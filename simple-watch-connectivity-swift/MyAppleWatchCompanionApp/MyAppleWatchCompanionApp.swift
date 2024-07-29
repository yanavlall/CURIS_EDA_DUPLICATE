//
//  MyAppleWatchCompanionApp.swift
//  MyAppleWatchCompanionApp
//

import SwiftUI

@main
struct MyAppleWatchCompanionApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    let workoutManager = WorkoutManager.shared
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(workoutManager)
        }
    }
}

