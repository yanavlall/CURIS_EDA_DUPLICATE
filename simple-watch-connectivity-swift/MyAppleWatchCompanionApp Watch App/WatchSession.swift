//
//  WatchSession.swift
//  MyAppleWatchCompanionApp Watch App
//
//  Created by Giovanni Tjahyamulia on 20/10/23.
//

// 1. import
import Foundation
import WatchConnectivity
import WatchKit

class WatchSession: NSObject, ObservableObject {
    // 2. initialize WCSession
    var wcSession: WCSession?
    
    // 7. initialize published variable to get data
    @Published var receivedData: String = "Haven't received any data"
    
    // 3. init
    override init() {
        super.init()
        
        // 4. WCSession delegate and activate
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }
}

// 5. delegate WCSession
extension WatchSession: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        // do something when active
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue)")
    }
    
    // 6. receive data
    // a. via Message
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["key"] as? String {
            DispatchQueue.main.async {
                self.receivedData = data

                let type = message["type"] as? String
                
                // Trigger haptic feedback based on the message content
                if type == "first" {
                    WKInterfaceDevice.current().play(.success)
                } else {
                    WKInterfaceDevice.current().play(.notification)
                }
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        // handle reachability changes if necessary
    }
}


// Add this method to handle received application context
/*func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    if let data = applicationContext["key"] as? String {
        DispatchQueue.main.async {
            self.receivedData = data

            WKInterfaceDevice.current().play(.success)
        }
    }
}*/
