//
//  E4linkManager.swift
//  MyAppleWatchApp
//

import Foundation
import Zip
import HealthKit

class E4linkManager: NSObject, ObservableObject {
    static let shared = E4linkManager()
    
    @Published var devices: [EmpaticaDeviceManager] = []
    @Published var deviceStatus = "Disconnected"
    
    var EDAstruct = CSVlog(filename: "EDA.csv")
    var BVPstruct = CSVlog(filename: "BVP.csv")
    var TEMPstruct = CSVlog(filename: "TEMP.csv")
    var ACCstruct = CSVlog(filename: "ACC.csv")
    var IBIstruct = CSVlog(filename: "IBI.csv")
    var TAGstruct = CSVlog(filename: "TAG.csv")
    var FEATUREstruct = CSVlog(filename: "FEATURE.csv")
    
    @Published var batteryLevel: Float = 0.0
    
    @Published var absGSR: Float = 0.0
    @Published var threshold: Float = 3.0
    @Published var GSRList: [Float] = []
    @Published var current_index = 0
    @Published var featureDetected: Bool = false
    @Published var shouldPersistData: Bool = true
    
    var baseline: Float = 0.0
    var flag: Bool = false
    var maintainFlag: Bool = false
    var isCollectingInitialData: Bool = true
    var featureIndices: [(Int, Int)] = []
    let oneMinuteBufferSize = 1 * 60 * 4
    var samplingRate: Int = 4
    let collectionDuration = 6 * 60 * 60 * 4 // Testing - 5 minutes, Actual - 6 hours
    var feature_start = 0
    var feature_end = 0
    var lastFeatureCheckIndex = 0
    
    var allDisconnected: Bool {
        return self.devices.reduce(true) { (value, device) -> Bool in
            value && device.deviceStatus == kDeviceStatusDisconnected
        }
    }
    
    func authenticate() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            EmpaticaAPI.authenticate(withAPIKey: "356898fe519245c08f6f96cc74e38e23") { (status, message) in
                if status {
                    print("Authenticated successfully: \(message ?? "")")
                    DispatchQueue.main.async {
                        self.discover()
                    }
                } else {
                    print("Failed to authenticate: \(message ?? "")")
                }
            }
        }
    }
    
    func notify(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default // Ensure sound is set.
        content.badge = NSNumber(value: 1) // Optionally set badge.

        let notification = UNNotificationRequest(identifier: "com.example.mynotification", content: content, trigger: nil)
        
        center.add(notification) { error in
            if let error = error {
                print("Failed to add notification: \(error)")
            } else {
                print("Notification added successfully.")
            }
        }
    }
    
    func discover() {
        print("Discovering...")
        EmpaticaAPI.discoverDevices(with: self)
    }
    
    func connect(device: EmpaticaDeviceManager) {
        device.connect(with: self)
    }
    
    func disconnect(device: EmpaticaDeviceManager) {
        if device.deviceStatus == kDeviceStatusConnected {
            device.disconnect()
        }
        else if device.deviceStatus == kDeviceStatusConnecting {
            device.cancelConnection()
        }
    }
    
    func select(device: EmpaticaDeviceManager) {
        print("Selecting...")
        EmpaticaAPI.cancelDiscovery()
        if device.deviceStatus == kDeviceStatusConnected || device.deviceStatus == kDeviceStatusConnecting {
            self.disconnect(device: device)
        } else if !device.isFaulty && device.allowed {
            self.connect(device: device)
        }
    }
    
    func deviceStatusDisplay(status : DeviceStatus) -> String {
        switch status {
        case kDeviceStatusDisconnected:
            return "Disconnected"
        case kDeviceStatusConnecting:
            return "Connecting..."
        case kDeviceStatusConnected:
            return "Connected"
        case kDeviceStatusFailedToConnect:
            return "Failed to connect"
        case kDeviceStatusDisconnecting:
            return "Disconnecting..."
        default:
            return "Unknown"
        }
    }
    
    func restartDiscovery() {
        print("restartDiscovery")
        guard EmpaticaAPI.status() == kBLEStatusReady else { return }
        if self.allDisconnected {
            print("restartDiscovery • allDisconnected")
            self.discover()
        }
    }
}

extension E4linkManager: EmpaticaDelegate {
    func didDiscoverDevices(_ devices: [Any]!) {
        print("didDiscoverDevices")
        if self.allDisconnected {
            print("didDiscoverDevices • allDisconnected")
            self.devices.removeAll()
            self.devices.append(contentsOf: devices as! [EmpaticaDeviceManager])
            DispatchQueue.main.async {
                if self.allDisconnected {
                    EmpaticaAPI.discoverDevices(with: self)
                }
            }
        }
    }
        
    func didUpdate(_ status: BLEStatus) {
        switch status {
        case kBLEStatusReady:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusReady")
            break
        case kBLEStatusScanning:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusScanning")
            break
        case kBLEStatusNotAvailable:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusNotAvailable")
            break
        default:
            print("[didUpdate] status \(status.rawValue)")
        }
    }
}

extension E4linkManager: EmpaticaDeviceDelegate {
    @MainActor
    func didReceiveGSR(_ gsr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        let workoutManager = WorkoutManager.shared
        
        if (!EDAstruct.headerSet) {
            EDAstruct.content.append(String(timestamp)+"\n")
            EDAstruct.content.append("4.000000"+"\n")
            EDAstruct.headerSet = true
        }
        EDAstruct.content.append(String(absGSR)+"\n")

        DispatchQueue.main.async {
            self.absGSR = abs(gsr)
            self.GSRList.append(self.absGSR)
            self.current_index += 1
        }
        if shouldPersistData {
            Task {
                do {
                    try await self.save(gsrList: self.GSRList)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
        }
        print("EDA value : \(absGSR), Current Index: \(current_index)")
        
        // 6 hour Data Collection
        if isCollectingInitialData {
            if GSRList.count >= collectionDuration {
                
                isCollectingInitialData = false
                
                // Clean the signal before calculations
                let cleanedSignal = smooth(signal: GSRList, windowSize: 20)
                
                DispatchQueue.main.async {
                    self.threshold = self.calculateThreshold(from: cleanedSignal)
                }
                
                lastFeatureCheckIndex = current_index
                print("Initial data collection completed. Baseline: \(baseline), Threshold: \(threshold), Time: \(current_index / oneMinuteBufferSize)")
                
                // Stop persisting data after reaching collectionDuration
                DispatchQueue.main.async {
                  self.shouldPersistData = false
                }
            }
        // Real-time Feature detection starts
        }
            
        if !featureDetected {
            if (current_index - lastFeatureCheckIndex) % oneMinuteBufferSize == 0 {
                lastFeatureCheckIndex = current_index
                print("One Minute Passed, Feature Flag is down \(current_index), Time: \(current_index / oneMinuteBufferSize)")
                if didDetectFeature(signal: GSRList, currentIndex: current_index) {
                    DispatchQueue.main.async {
                        self.featureDetected = true
                    }
                    feature_start = current_index
                    print("Feature detection started at index \(current_index), Time: \(current_index / oneMinuteBufferSize)")
                    print("Flag up")
                    
                    Task {
                        do {
                            try await workoutManager.startWatchWorkout(workoutType: .cycling)
                        } catch {
                            print("Failed to start cycling on the paired watch.")
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        print("DISPATCHED")
                        workoutManager.resetWorkout()
                    }
                }
            }
        
        } else {
            if (current_index - feature_start) % oneMinuteBufferSize == 0 {
                print("One Minute Passed, Feature Flag is up at index:\(current_index), Time: \(current_index / oneMinuteBufferSize)")
                if !postFeatureCheck(signal: GSRList, currentIndex: current_index) {
                    DispatchQueue.main.async {
                        self.featureDetected = false
                    }
                    feature_end = current_index
                    print("Feature detection ended at index \(current_index), Time: \(current_index / oneMinuteBufferSize)")
                    FEATUREstruct.content.append(String(feature_start)+","+String(feature_end)+"\n")
                    featureIndices.append((feature_start, feature_end))
                    
                    Task {
                        do {
                            try await workoutManager.startWatchWorkout(workoutType: .cycling)
                        } catch {
                            print("Failed to start cycling on the paired watch.")
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        print("DISPATCHED")
                        workoutManager.resetWorkout()
                    }
                }
            }
        }
    }
    
    func calculateThreshold(from data: [Float]) -> Float {
        let sortedData = data.sorted()
        let perc25Index = Int(0.25 * Double(sortedData.count))
        let perc75Index = Int(0.75 * Double(sortedData.count))
        
        let perc25 = sortedData[perc25Index]
        let perc75 = sortedData[perc75Index]
        
        let filteredData = data.filter { $0 > perc25 && $0 < perc75 }
        let baseline = filteredData.reduce(0, +) / Float(filteredData.count)
        
        print("Calculated Threshold: \(1.2 * baseline)")
        return 1.2 * baseline
    }


    // Implement Moving Average to Smooth the Signal
    func smooth(signal: [Float], windowSize: Int) -> [Float] {
        guard windowSize > 1 else { return signal }
        var smoothedSignal: [Float] = []
        for i in 0..<signal.count {
            let start = max(0, i - windowSize / 2)
            let end = min(signal.count, i + windowSize / 2)
            let window = Array(signal[start..<end])
            let average = window.reduce(0, +) / Float(window.count)
            smoothedSignal.append(average)
        }
        return smoothedSignal
    }
    
    // Go back  15 minutes in time, check if mean is over threshold throughout that period,
    func didDetectFeature(signal: [Float], currentIndex: Int) -> Bool {
        let chunkSize = 5 * 60 * samplingRate
        let lookBackPeriod = 15 * 60 * samplingRate // 15 minutes in data points - Actual
        
        // let chunkSize = 30 * samplingRate
        // let lookBackPeriod = 3 * 60 * samplingRate
        
        guard currentIndex >= lookBackPeriod else {
            print("DidDetectFeature - Not enough data for feature detection at index \(currentIndex)")
            return false
        }
        
        // Clean the signal before calculations
        let cleanedSignal = smooth(signal: signal, windowSize: 20)
        
        for i in 0..<3 { // CHANGE TO 3 WHEN DONE WITH TESTING
            let chunkStart = currentIndex - lookBackPeriod + (i * chunkSize)
            let chunkEnd = min(chunkStart + chunkSize, cleanedSignal.count)
            let chunk = Array(cleanedSignal[chunkStart..<chunkEnd])
            let meanChunk = chunk.reduce(0, +) / Float(chunk.count)
            
            print("Chunk \(i): mean = \(meanChunk), threshold = \(threshold), chunkStart = \(chunkStart), chunkEnd = \(chunkEnd)")

            if meanChunk <= threshold {
                return false
            }
        }
        return true
        
    }
    
    // Every one minute after the feature is detected, you check if the last 10 minutes had mean > threshold, keep doing this until not true
    func postFeatureCheck(signal: [Float], currentIndex: Int) -> Bool {
        let lookBackPeriod = 10 * 60 * samplingRate // 10 minutes in data points - Actual
    //  let lookBackPeriod = 2 * 60 * samplingRate
        
        guard currentIndex >= lookBackPeriod else {
            print("postFeatureCheck - Not enough data for feature detection at index \(currentIndex)")
            return false
        }
    
        // Clean the signal before calculations
        let cleanedSignal = smooth(signal: signal, windowSize: 20)
        
        let lookBackStart = currentIndex - lookBackPeriod
        let lookBackEnd = currentIndex
        let lookBackChunk = Array(cleanedSignal[lookBackStart..<lookBackEnd])
        let meanChunk = lookBackChunk.reduce(0, +) / Float(lookBackChunk.count)
        
    if meanChunk > threshold {
        print("PostFeatureChecking Continuing")
    }
        return meanChunk > threshold
    }
    
    func didReceiveBVP(_ bvp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if (!BVPstruct.headerSet) {
            BVPstruct.content.append(String(timestamp)+"\n")
            BVPstruct.content.append("64.000000"+"\n")
            BVPstruct.headerSet = true
        }
        BVPstruct.content.append(String(bvp)+"\n")
    }
    
    func didReceiveTemperature(_ temp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if (!TEMPstruct.headerSet) {
            TEMPstruct.content.append(String(timestamp)+"\n")
            TEMPstruct.content.append("4.000000"+"\n")
            TEMPstruct.headerSet = true
        }
        TEMPstruct.content.append(String(temp)+"\n")
    }
    
    func didReceiveAccelerationX(_ x: Int8, y: Int8, z: Int8, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if (!ACCstruct.headerSet) {
            ACCstruct.content.append(String(timestamp)+"\n")
            ACCstruct.content.append("32.000000, 32.000000, 32.000000"+"\n")
            ACCstruct.headerSet = true
        }
        ACCstruct.content.append(String(x)+","+String(y)+","+String(z)+"\n")
    }
    
    func didReceiveIBI(_ ibi: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if (!IBIstruct.headerSet) {
            IBIstruct.content.append(String(timestamp)+", IBI\n")
            IBIstruct.headerSet = true
        }
        if (IBIstruct.prevSet) {
            let diff = ibi - IBIstruct.prev
            IBIstruct.content.append(String(ibi)+","+String(diff))
            IBIstruct.prev = ibi
        } else {
            IBIstruct.prev = ibi
            IBIstruct.prevSet = true
        }
    }
    
    func didReceiveBatteryLevel(_ level: Float, withTimestamp timestamp: Double, fromDevice: EmpaticaDeviceManager!) {
        DispatchQueue.main.async {
            self.batteryLevel = level
        }
    }

    func didReceiveTag(_ timestamp: Double, fromDevice: EmpaticaDeviceManager!) {
        print("TAG")
        TAGstruct.content.append(String(timestamp)+"\n")
    }
    
    func didUpdate( _ status: DeviceStatus, forDevice device: EmpaticaDeviceManager!) {
        switch status {
        case kDeviceStatusDisconnected:
            print("[didUpdate] Disconnected \(device.serialNumber!).")
            self.notify(title: "E4 Disconnected", body: "Rediscover and reconnect to continue streaming.")
            self.saveSession()
            self.restartDiscovery()
            break
        case kDeviceStatusConnecting:
            print("[didUpdate] Connecting \(device.serialNumber!).")
            break
        case kDeviceStatusConnected:
            print("[didUpdate] Connected \(device.serialNumber!).")
            break
        case kDeviceStatusFailedToConnect:
            print("[didUpdate] Failed to connect \(device.serialNumber!).")
            self.restartDiscovery()
            break
        case kDeviceStatusDisconnecting:
            print("[didUpdate] Disconnecting \(device.serialNumber!).")
            break
        default:
            break
        }
        self.deviceStatus = deviceStatusDisplay(status: device.deviceStatus)
    }
    
    func didUpdate(_ onWristStatus: SensorStatus, forDevice device: EmpaticaDeviceManager!) {
        switch onWristStatus {
        case kE2SensorStatusNotOnWrist: 
            print("[didUpdate] Sensor not on Wrist.")
            self.notify(title: "E4 Not on Wrist", body: "Adjust sensor more tightly on wrist.")
            break
        case kE2SensorStatusOnWrist:
            print("[didUpdate] Sensor on Wrist.")
            break
        case kE2SensorStatusDead:
            print("[didUpdate] Sensor is Dead.")
            self.notify(title: "E4 Out of Battery", body: "Charge the device to continue use.")
            break
        default:
            break
        }
    }
    
    func saveSession() {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy!HH:mm:ss"
        let dayInWeek = dateFormatter.string(from: date)
        let filename = "Session::" + dayInWeek
        self.EDAstruct.writeToUrl()
        self.BVPstruct.writeToUrl()
        self.TEMPstruct.writeToUrl()
        self.ACCstruct.writeToUrl()
        self.IBIstruct.writeToUrl()
        self.TAGstruct.writeToUrl()
        self.FEATUREstruct.writeToUrl()
        
        do {
            let path = try Zip.quickZipFiles([EDAstruct.path, BVPstruct.path, TEMPstruct.path, ACCstruct.path, IBIstruct.path, TAGstruct.path, FEATUREstruct.path], fileName: filename)
            // file:///var/mobile/Containers/Data/Application/D4BD4F66-E243-44A7-AF99-8C6ACDDDAF99/Documents/Session::13-07-2024!01:56:59.zip
            print(path.absoluteString)
        } catch {
            print("Something went wrong...")
        }
        self.resetFiles()
    }
    
    func resetFiles() {
        self.EDAstruct = CSVlog(filename: "EDA.csv")
        self.BVPstruct = CSVlog(filename: "BVP.csv")
        self.TEMPstruct = CSVlog(filename: "TEMP.csv")
        self.ACCstruct = CSVlog(filename: "ACC.csv")
        self.IBIstruct = CSVlog(filename: "IBI.csv")
        self.TAGstruct = CSVlog(filename: "TAG.csv")
        self.FEATUREstruct = CSVlog(filename: "FEATURE.csv")
    }

    func load() async throws {
        print("LOADED")
        let task = Task<[Float], Error> {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("gsrlist.data")
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            let gsrList = try JSONDecoder().decode([Float].self, from: data)
            return gsrList
        }
        let list = try await task.value
        
        DispatchQueue.main.async {
            self.GSRList = list
            self.current_index = self.GSRList.count
            print("COUNT: ", self.GSRList.count)
        }
    }

    func save(gsrList: [Float]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(gsrList)
            let outfile = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("gsrlist.data")
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
    
}

import Foundation

struct CSVlog {
    let filename: String
    var content: String
    var headerSet: Bool
    var prevSet: Bool
    var prev: Float
    var path: URL

    init(filename: String) {
        self.filename = filename
        self.content = ""
        self.headerSet = false
        self.prevSet = false
        self.prev = 0.0
        self.path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
    }

    func writeToUrl() {
        do {
            // file:///private/var/mobile/Containers/Data/Application/D4BD4F66-E243-44A7-AF99-8C6ACDDDAF99/tmp/ACC.csv
            try content.write(to: path, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create file for export ...")
            print("\(error)")
        }
    }
}
