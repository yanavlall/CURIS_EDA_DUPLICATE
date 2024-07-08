//
//  E4linkManager.swift
//  MyAppleWatchApp
//

import Foundation

class E4linkManager: NSObject, ObservableObject {
    static let shared = E4linkManager()
    
    @Published var devices: [EmpaticaDeviceManager] = []
    
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
        print("Updated!")
        print(status)
    }
}

extension E4linkManager: EmpaticaDeviceDelegate {}
