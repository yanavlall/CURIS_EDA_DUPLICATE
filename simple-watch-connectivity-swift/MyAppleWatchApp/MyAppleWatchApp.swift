//
//  MyAppleWatchApp.swift
//  MyAppleWatchApp
//

import SwiftUI

@main
struct MyAppleWatchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let workoutManager = WorkoutManager.shared
    
    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .phone {
                ContentView(workoutManager: workoutManager)
            }
        }
    }
}

