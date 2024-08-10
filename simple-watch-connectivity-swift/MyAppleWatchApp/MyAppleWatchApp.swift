//
//  MyAppleWatchApp.swift
//  MyAppleWatchApp
//

import SwiftUI

@main
struct MyAppleWatchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
