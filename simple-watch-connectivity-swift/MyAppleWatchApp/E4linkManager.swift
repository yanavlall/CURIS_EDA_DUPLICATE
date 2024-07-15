//
//  E4linkManager.swift
//  MyAppleWatchApp
//

import Foundation
import Zip

class E4linkManager: NSObject, ObservableObject {
    static let shared = E4linkManager()
    
    @Published var devices: [EmpaticaDeviceManager] = []
    @Published var deviceStatus = "Disconnected"
    
    var ACCstruct = CSVlog(filename: "ACC.csv")
    
    var firstPress = true
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
        if self.firstPress {
            print("Selecting...")
            EmpaticaAPI.cancelDiscovery()
            if device.deviceStatus == kDeviceStatusConnected || device.deviceStatus == kDeviceStatusConnecting {
                self.disconnect(device: device)
            } else if !device.isFaulty && device.allowed {
                self.connect(device: device)
            }
            self.firstPress = false
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
            self.firstPress = true
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
    func didReceiveAccelerationX(_ x: Int8, y: Int8, z: Int8, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        self.ACCstruct.appendData(x: x, y: y, z: z, withTimestamp: timestamp)
    }
    
    func didUpdate( _ status: DeviceStatus, forDevice device: EmpaticaDeviceManager!) {
        switch status {
        case kDeviceStatusDisconnected:
            print("[didUpdate] Disconnected \(device.serialNumber!).")
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
    
    func saveSession() {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy!HH:mm:ss"
        let dayInWeek = dateFormatter.string(from: date)
        let filename = "Session::" + dayInWeek

        self.ACCstruct.writeToUrl()
        /*BVPstruct.writeToUrl()
        EDAstruct.writeToUrl()
        TEMPstruct.writeToUrl()
        IBIstruct.writeToUrl()
        HRstruct.writeToUrl()*/

        do {
            let path = try Zip.quickZipFiles([self.ACCstruct.path], fileName: filename)
            // file:///var/mobile/Containers/Data/Application/D4BD4F66-E243-44A7-AF99-8C6ACDDDAF99/Documents/Session::13-07-2024!01:56:59.zip
            print(path.absoluteString)
        } catch {
            print("Something went wrong...")
        }
        self.resetFiles()
    }
    
    func resetFiles() {
        self.ACCstruct = CSVlog(filename: "ACC.csv")
    }
}

struct CSVlog {
    let filename: String
    var path: URL
    var headerSet: Bool = false
    var content: String = ""

    init(filename: String) {
        self.filename = filename
        self.path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
    }

    mutating func appendData(x: Int8, y: Int8, z: Int8, withTimestamp timestamp: Double) {
        if !headerSet {
            content.append("\(timestamp)\n32.000000, 32.000000, 32.000000\n")
            headerSet = true
        }
        content.append("\(x),\(y),\(z)\n")
    }

    func writeToUrl() {
        do {
            // file:///private/var/mobile/Containers/Data/Application/D4BD4F66-E243-44A7-AF99-8C6ACDDDAF99/tmp/ACC.csv
            try content.write(to: path, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to create file for export ...")
            print("\(error)")
        }
    }
}
