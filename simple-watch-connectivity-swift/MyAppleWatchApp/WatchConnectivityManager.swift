//
//  WatchConnectivityManager.swift
//  MyAppleWatchApp
//
//  Created by Katie Liu on 6/28/24.
//

// 1. import
import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }

    // 2. initialize Watch Session
    var wcSession: WCSession?
    
    private func setupWatchConnectivity() {
        // 4. check Watch Session is supported or not
        if WCSession.isSupported() {
            // 5. Watch Session delegate and activate
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        } else {
            print("WCSession is not supported on this device.")
        }
    }

    func sendDataFromPhone() {
        // 6. create data as dictionary
        let dict: [String: Any] = ["key": "Data Received", "type": "first"]
        
        // 7. send data to Watch App
        do {
            // b. via Message
            wcSession?.sendMessage(dict, replyHandler: nil)     // removed a try
            print("Data sent: \(dict)")
        }
    }
    
    func sendDataFromPhonePt2() {
        // 6. create data as dictionary
        let dict: [String: Any] = ["key": "Data Received", "type": "second"]
        
        // 7. send data to Watch App
        do {
            // b. via Message
            wcSession?.sendMessage(dict, replyHandler: nil)     // removed a try
            print("Data sent: \(dict)")
        }
    }

    // 3. delegate Watch Session
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // do something when activation complete
        
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // do something when will be inactive
        print("WCSession did become inactive")
        
        // activate when it will be inactive
        wcSession?.activate()
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // do something when inactive
        print("WCSession did deactivate")
        
        // activate when inactive
        wcSession?.activate()
    }
}


/*func sendDataFromPhonePt2() {
    // 6. create data as dictionary
    let dict: [String: Any] = ["key": "Data Received", "type": "second"]
    
    // 7. send data to Watch App
    do {
        // a. via Application Context
        try wcSession?.updateApplicationContext(dict)
        print("Data sent: \(dict)")
    
    } catch {
        print("Failed to send data: \(error.localizedDescription)")
    }
}*/
