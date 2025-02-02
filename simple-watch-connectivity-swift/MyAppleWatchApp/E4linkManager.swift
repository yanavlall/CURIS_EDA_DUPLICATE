//
//  E4linkManager.swift
//  MyAppleWatchApp
//

import Zip
import SwiftUI

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
    
    @Published var threshold: Float = 3.0
    @Published var batteryLevel: Int = 0
    @Published var useManualThreshold: Bool = false // Track if the manual threshold is being used
    @Published var manualThreshold: Float = 3.0 // Initial manual threshold
    @Published var activeThreshold: Float = 0.0
    @Published var featureState: FeatureState = .off
    
    enum FeatureState {
        case off
        case on
        case goingDown
        case goingUp
    }

    var didCollectData: Bool = false
    var showSurveyButton = false
    var showSurvey = false

    @Published var absGSR: Float = 0.0
    @Published var featureDetected: Bool = false
    var GSRList: [Float] = []
    var zeroGSR: Float = 0.0
    var current_index: Int = 0
    var shouldPersistData: Bool = true
    var baseline: Float = 0.0
    var flag: Bool = false
    var maintainFlag: Bool = false
    var isCollectingInitialData: Bool = true
    var featureTimestamps: [(Double, Double)] = []
    var oneMinuteBufferSize: Int = 1 * 60 * 4
    var samplingRate: Int = 4
    var collectionDuration: Int = 6 * 60 * 60 * 4 // Testing - 5 minutes, Actual - 6 hours
    var oneMinuteTimestampBufferSize: Int = 60
    var featureStateChangeList: [(Double, FeatureState)] = []
    var feature_start: Double = 0
    var feature_end: Double = 0
    var lastFeatureCheckIndex: Int = 0
    var previousFeatureState: FeatureState = .off // Initialize with the default state

    
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
    
    func notify(title: String, body: String, sound: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound(named: UNNotificationSoundName(sound)) // Ensure sound is set.
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
    func didReceiveGSR(_ gsr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        DispatchQueue.main.async {
            print("EDA value : \(self.absGSR), Current Index: \(self.current_index)")
            
            self.absGSR = abs(gsr)
            
            if (!self.EDAstruct.headerSet) {
                self.EDAstruct.content.append("Timestamp, GSR Value\n")
                self.EDAstruct.headerSet = true
            }
            self.EDAstruct.content.append("\(timestamp), \(self.absGSR)\n")
            
            // Update state variables
            self.didCollectData = true
            if self.absGSR != self.zeroGSR {
                self.GSRList.append(self.absGSR)
                self.current_index += 1
            }
            // Save data if required
            if self.shouldPersistData {
                Task {
                    do {
                        try await self.save(gsrList: self.GSRList)
                    } catch {
                        fatalError(error.localizedDescription)
                    }
                }
            }
            
            // 6 hour data collection
            if self.isCollectingInitialData {
                if self.GSRList.count >= self.collectionDuration {
                    
                    self.isCollectingInitialData = false
                    
                    // Clean the signal before calculations
                    let cleanedSignal = self.smooth(signal: self.GSRList, windowSize: 20)
                    
                    self.threshold = self.calculateThreshold(from: cleanedSignal)
                    
                    self.lastFeatureCheckIndex = self.current_index
                    print("Initial data collection completed. Baseline: \(self.baseline), Threshold: \(self.threshold), Time: \(timestamp)")
                    
                    // Stop persisting data after reaching collectionDuration
                    self.shouldPersistData = false
                }
                // Real-time feature detection starts
            }
            
            if !self.featureDetected {
                if (Int(timestamp - self.feature_start)) % self.oneMinuteTimestampBufferSize == 0 {
                    self.lastFeatureCheckIndex = self.current_index
                    print("One Minute Passed, Feature Flag is down \(self.current_index), Time: \(timestamp)")
                    
                    let newState = self.didDetectFeature(signal: self.GSRList, currentIndex: self.current_index)
                    // Only log the state change if it is different from the previous state
                    if newState != self.previousFeatureState {
                        self.featureStateChangeList.append((timestamp, newState))
                        self.previousFeatureState = newState // Update the previous state
                    }
                    
                    self.featureState = newState // Set the current state
                    
                    if newState == .on {
                        self.featureDetected = true
                        self.feature_start = timestamp
                        print("Feature detection started at index \(self.current_index), Time: \(timestamp)")
                        print("Flag up")
                        
                        WatchConnectivityManager.shared.sendDataFromPhone()
                        self.notify(title: "E4 Feature Detected", body: "EDA level above threshold.", sound: "positive.wav")
                        
                    } else if self.featureState == .goingUp {
                        self.featureState = .goingUp
                        print("Feature is going up. Current Index: \(self.current_index)")
                    }
                }
                
            } else {
                if (Int(timestamp - self.feature_start)) % self.oneMinuteTimestampBufferSize == 0 {
                    print("One Minute Passed, Feature Flag is up at index:\(self.current_index), Time: \(timestamp)")
                    let newState = self.postFeatureCheck(signal: self.GSRList, currentIndex: self.current_index)
                    
                    // Only log the state change if it is different from the previous state
                    if newState != self.previousFeatureState {
                        self.featureStateChangeList.append((timestamp, newState))
                        self.previousFeatureState = newState // Update the previous state
                    }
                    
                    self.featureState = newState // Set the current state
                    
                    if newState == .off {
                        self.featureDetected = false
                        self.feature_end = timestamp
                        print("Feature detection ended at index \(self.current_index), Time: \(self.current_index / self.oneMinuteBufferSize)")
                        self.FEATUREstruct.content.append(String(self.feature_start)+","+String(self.feature_end)+"\n")
                        self.featureTimestamps.append((self.feature_start, self.feature_end))
                        
                        WatchConnectivityManager.shared.sendDataFromPhonePt2()
                        self.notify(title: "E4 Feature Ended", body: "EDA level below threshold.", sound: "negative.wav")
                        self.showSurveyButton = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1800) {
                            self.showSurveyButton = false
                        }
                        
                    } else if self.featureState == .goingDown {
                        print("Feature is going down. Current Index: \(self.current_index)")
                        // Feature is decaying but not completely off yet
                    }
                }
            }
        }
    }
    
    ///Don't include Zeroes in the Calculation
    
    func calculateThreshold(from data: [Float]) -> Float {
        let sortedData = data.sorted()
        let perc25Index = Int(0.25 * Double(sortedData.count))
        let perc75Index = Int(0.75 * Double(sortedData.count))
        
        let perc25 = sortedData[perc25Index]
        let perc75 = sortedData[perc75Index]
        
        let filteredData = data.filter { $0 > perc25 && $0 < perc75 }
        let baseline = filteredData.reduce(0, +) / Float(filteredData.count)
        
        print("Calculated Threshold: \(1.5 * baseline)")
        return 1.5 * baseline
    }


    // Implement moving average to smooth the signal
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
    
    // Go back 15 minutes in time, check if mean is over threshold throughout that period
    func didDetectFeature(signal: [Float], currentIndex: Int) -> FeatureState {
        let activeThreshold = useManualThreshold ? manualThreshold : threshold
        let chunkSize = 5 * 60 * self.samplingRate
        let lookBackPeriod = 15 * 60 * self.samplingRate // 15 minutes in data points - Actual
        
        guard currentIndex >= lookBackPeriod else {
            print("didDetectFeature - Not enough data for feature detection at index \(currentIndex)")
            return .off // Not enough data to determine
        }

        // Clean the signal before calculations
        let cleanedSignal = self.smooth(signal: signal, windowSize: 20)

        var aboveThresholdCount = 0

        for i in 0..<3 {
            let chunkStart = currentIndex - lookBackPeriod + (i * chunkSize)
            let chunkEnd = min(chunkStart + chunkSize, cleanedSignal.count)
            let chunk = Array(cleanedSignal[chunkStart..<chunkEnd])
            let meanChunk = chunk.reduce(0, +) / Float(chunk.count)
            
            print("Chunk \(i): mean = \(meanChunk), threshold = \(self.threshold), chunkStart = \(chunkStart), chunkEnd = \(chunkEnd)")

            if meanChunk > activeThreshold {
                aboveThresholdCount += 1
            }
        }

        // Determine the feature state based on the number of chunks above the threshold
        switch aboveThresholdCount {
        case 3:
            return .on // All chunks are above threshold, fully detected feature
        case 1...2:
            return .goingUp // Partial detection, feature is "going up"
        default:
            return .off // Not enough above-threshold chunks, feature not detected
        }
    }

    // Every one minute after the feature is detected, you check if the last 10 minutes had mean > threshold, keep doing this until not true
    func postFeatureCheck(signal: [Float], currentIndex: Int) -> FeatureState {
        let activeThreshold = useManualThreshold ? manualThreshold : threshold
        let chunkSize = 5 * 60 * self.samplingRate
        let lookBackPeriod = 15 * 60 * self.samplingRate // 15 minutes in data points - Actual
        
        guard currentIndex >= lookBackPeriod else {
            print("postFeatureCheck - Not enough data for post-feature check at index \(currentIndex)")
            return .on // Continue as "on" if not enough data
        }

        // Clean the signal before calculations
        let cleanedSignal = self.smooth(signal: signal, windowSize: 20)

        var belowThresholdCount = 0

        for i in 0..<3 {
            let chunkStart = currentIndex - lookBackPeriod + (i * chunkSize)
            let chunkEnd = min(chunkStart + chunkSize, cleanedSignal.count)
            let chunk = Array(cleanedSignal[chunkStart..<chunkEnd])
            let meanChunk = chunk.reduce(0, +) / Float(chunk.count)
            
            print("Chunk \(i): mean = \(meanChunk), threshold = \(self.threshold), chunkStart = \(chunkStart), chunkEnd = \(chunkEnd)")

            if meanChunk <= activeThreshold {
                belowThresholdCount += 1
            }
        }

        // Determine the feature state based on the number of chunks below the threshold
        switch belowThresholdCount {
        case 3:
            return .off // All chunks are below threshold, feature ends
        case 1...2:
            return .goingDown // Partial feature decay, going down
        default:
            return .on // Feature is still on
        }
    }


    func didReceiveBVP(_ bvp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if (!self.BVPstruct.headerSet) {
            self.BVPstruct.content.append("Timestamp, BVP\n")
            self.BVPstruct.headerSet = true
        }
        self.BVPstruct.content.append("\(timestamp), \(bvp)\n")
    }
    
    func didReceiveTemperature(_ temp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if (!self.TEMPstruct.headerSet) {
            self.TEMPstruct.content.append("Timestamp, Temperature\n")
            self.TEMPstruct.headerSet = true
        }
        self.TEMPstruct.content.append("\(timestamp), \(temp)\n")
    }
    
    func didReceiveAccelerationX(_ x: Int8, y: Int8, z: Int8, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if (!self.ACCstruct.headerSet) {
            self.ACCstruct.content.append("Timestamp, AccelerationX, AccelerationY, AccelerationZ\n")
            self.ACCstruct.headerSet = true
        }
        self.ACCstruct.content.append("\(timestamp),\(x),\(y),\(z)\n")
    }
    
    func didReceiveIBI(_ ibi: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if (!self.IBIstruct.headerSet) {
            self.IBIstruct.content.append("Timestamp, IBI, Difference\n")
            self.IBIstruct.headerSet = true
        }
        
        if (self.IBIstruct.prevSet) {
            let diff = ibi - self.IBIstruct.prev
            self.IBIstruct.content.append("\(timestamp),\(ibi),\(diff)\n")
            self.IBIstruct.prev = ibi
        } else {
            // For the first IBI value, there's no difference to calculate
            self.IBIstruct.content.append("\(timestamp),\(ibi),\n")
            self.IBIstruct.prev = ibi
            self.IBIstruct.prevSet = true
        }
    }

    func didReceiveBatteryLevel(_ level: Float, withTimestamp timestamp: Double, fromDevice: EmpaticaDeviceManager!) {
        DispatchQueue.main.async {
            self.batteryLevel = Int(level * 100)
        }
    }
    
    func didReceiveTag(atTimestamp timestamp: Double, fromDevice: EmpaticaDeviceManager!) {
        self.TAGstruct.content.append(String(timestamp)+"\n")
    }
    
    func didUpdate( _ status: DeviceStatus, forDevice device: EmpaticaDeviceManager!) {
        switch status {
        case kDeviceStatusDisconnected:
            print("[didUpdate] Disconnected \(device.serialNumber!).")
            self.notify(title: "E4 Disconnected", body: "Rediscover and reconnect to continue streaming.", sound: "default")
            self.saveSession()
            DataManager.shared.reloadFiles()
            self.restartDiscovery()
            WatchConnectivityManager.shared.sendWorkoutEndFromPhone()
            break
        case kDeviceStatusConnecting:
            print("[didUpdate] Connecting \(device.serialNumber!).")
            break
        case kDeviceStatusConnected:
            print("[didUpdate] Connected \(device.serialNumber!).")
            DispatchQueue.main.async {
                WorkoutManager.shared.startWatchWorkout()
            }
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
    
    func didUpdate(onWristStatus: SensorStatus, forDevice device: EmpaticaDeviceManager!) {
        switch onWristStatus {
        case kE2SensorStatusNotOnWrist:
            self.notify(title: "E4 Not on Wrist", body: "Adjust sensor more tightly on wrist.", sound: "default")
            break
        case kE2SensorStatusOnWrist:
            self.notify(title: "E4 Looks Great", body: "Sensor is attached well. Thank you!", sound: "default")
            break
        case kE2SensorStatusDead:
            self.notify(title: "E4 Out of Battery", body: "Session saved. Charge sensor to continue use.", sound: "default")
            self.saveSession()
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
            let path = try Zip.quickZipFiles([self.EDAstruct.path, self.BVPstruct.path, self.TEMPstruct.path, self.ACCstruct.path, self.IBIstruct.path, self.TAGstruct.path, self.FEATUREstruct.path], fileName: filename)
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
        self.didCollectData = false
    }

    func load() async throws {
        let task = Task<[Float], Error> {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("gsrlist.data")
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            let gsrList = try JSONDecoder().decode([Float].self, from: data)
            return gsrList
        }
        let list = try await task.value
        
        self.GSRList = list
        self.current_index = self.GSRList.count
        print("GSRLIST COUNT: ", self.GSRList.count)
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
            try content.write(to: self.path, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create file for export ...")
            print("\(error)")
        }
    }
}
