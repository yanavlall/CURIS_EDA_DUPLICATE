//
//  WatchSession.swift
//  MyAppleWatchCompanionApp Watch App
//

import Foundation
import WatchConnectivity
import WatchKit
// import UserNotifications

class WatchSession: NSObject, ObservableObject {
    var wcSession: WCSession?
    
    // Initialize published variable to get data.
    @Published var receivedData: String = "Haven't received any data"
    
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
    /* func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }*/
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue)")
    }
    
    // Receive data via Message.
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["key"] as? String {
            DispatchQueue.main.async {
                self.receivedData = data

                let type = message["type"] as? String
                // Trigger haptic feedback based on the message content.
                if type == "first" {
                    WKInterfaceDevice.current().play(.success)
                    // self.sendNotification(title: "First Data Received", body: "You have received the first type of data.")
                } else {
                    WKInterfaceDevice.current().play(.notification)
                    // self.sendNotification(title: "Second Data Received", body: "You have received the second type of data.")
                }
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        // Handle reachability changes if necessary.
    }
}
