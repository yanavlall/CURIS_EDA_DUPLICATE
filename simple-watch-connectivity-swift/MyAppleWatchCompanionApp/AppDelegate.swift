//
//  AppDelegate.swift
//  MyAppleWatchCompanionApp
//

import HealthKit
import SwiftUI

class AppDelegate: NSObject, WKApplicationDelegate {
    @ObservedObject var workoutManager = WorkoutManager.shared
    
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Task {
            do {
                workoutManager.resetWorkout()
                try await workoutManager.startWorkout(workoutConfiguration: workoutConfiguration)
                print("Successfully started workout.")
            } catch {
                print("Failed to start workout.")
            }
        }
    }
}
