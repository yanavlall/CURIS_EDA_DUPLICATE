//
//  WatchConnectivityManager.swift
//  MyAppleWatchApp
//

import Foundation
import WatchConnectivity

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
        do {
            wcSession?.sendMessage(dict, replyHandler: nil)     // removed a try
            print("Data sent: \(dict)")
        }
    }
    
    func sendDataFromPhonePt2() {
        let dict: [String: Any] = ["key": "Data Received", "type": "second"]
        
        do {
            wcSession?.sendMessage(dict, replyHandler: nil)
            print("Data sent: \(dict)")
        }
    }

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
