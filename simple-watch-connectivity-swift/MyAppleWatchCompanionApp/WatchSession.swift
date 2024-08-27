//
//  WatchSession.swift
//  MyAppleWatchCompanionApp
//

import WatchConnectivity
import WatchKit

class WatchSession: NSObject, ObservableObject {
    static let shared = WatchSession()

    var wcSession: WCSession?
    
    // Initialize published variable to get data.
    @Published var receivedData: String = "Haven't received any data."
    
    // Init.
    override init() {
        super.init()
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }
}

// Delegate WCSession.
extension WatchSession: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription).")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue).")
    }
    
    // Receive data via Message.
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["key"] as? String {
            DispatchQueue.main.async {
                self.receivedData = data

                let type = message["type"] as? String
                // Trigger haptic feedback based on the message content.
                if type == "first" {
                    WKInterfaceDevice.current().play(.directionUp)
                } else if type == "second" {
                    WKInterfaceDevice.current().play(.directionDown)
                } else {
                    exit(0)
                }
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        // Handle reachability changes if necessary.
    }
}
