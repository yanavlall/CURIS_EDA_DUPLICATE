//
//  MyAppleWatchCompanionApp.swift
//  MyAppleWatchCompanionApp
//

import SwiftUI

@main
struct MyAppleWatchCompanionApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
