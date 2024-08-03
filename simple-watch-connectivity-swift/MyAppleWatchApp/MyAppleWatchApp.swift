//
//  MyAppleWatchApp.swift
//  MyAppleWatchApp
//

import SwiftUI

@main
struct MyAppleWatchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let workoutManager = WorkoutManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(workoutManager)
        }
    }
}
