//
//  AppDelegate.swift
//  MyAppleWatchApp
//

import SwiftUI
import UserNotifications
import HealthKit

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @ObservedObject var e4linkManager = E4linkManager.shared
    @ObservedObject var workoutManager = WorkoutManager.shared
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if let error = error {
                print("Request authorization failed: \(error.localizedDescription).")
            } else if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
        
        EmpaticaAPI.initialize()
        workoutManager.requestAuth()
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle the notification when the app is in the foreground.
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the user's response to the notification.
        completionHandler()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        startBackgroundTask()
        EmpaticaAPI.prepareForBackground()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
        endBackgroundTask()
        EmpaticaAPI.prepareForResume()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if (e4linkManager.didCollectData) {
            e4linkManager.saveSession()
        }
        e4linkManager.notify(title: "E4 Terminated", body: "Please reopen app and restart discovery.", sound: "default")
        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        EmpaticaAPI.cancelDiscovery()
    }
    
    func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
        assert(backgroundTask != .invalid)
    }

    func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
