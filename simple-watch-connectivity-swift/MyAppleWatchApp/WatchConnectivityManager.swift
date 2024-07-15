//
//  WatchConnectivityManager.swift
//  MyAppleWatchApp
//

import Foundation
import WatchConnectivity
import UserNotifications

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }

    // Initialize Watch Session.
    var wcSession: WCSession?
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        } else {
            print("WCSession is not supported on this device.")
        }
    }

    func sendDataFromPhone() {
        // Create data as dictionary.
        let dict: [String: Any] = ["key": "Data Received", "type": "first"]
        
        // Send data to Watch App via Message.
        wcSession?.sendMessage(dict, replyHandler: nil)
        print("Data sent: \(dict)")
        
        //sendNotification(title: "Data Sent", body: "First-type data sent to Apple Watch")

    }
    
    func sendDataFromPhonePt2() {
        let dict: [String: Any] = ["key": "Data Received", "type": "second"]
        
        wcSession?.sendMessage(dict, replyHandler: nil)
        print("Data sent: \(dict)")
        
        //sendNotification(title: "Data Sent", body: "Second-type data sent to Apple Watch")

    }
    
    /*func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }*/

    // Delegate Watch Session.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession did become inactive")
        wcSession?.activate()
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession did deactivate")
        wcSession?.activate()
    }
}
