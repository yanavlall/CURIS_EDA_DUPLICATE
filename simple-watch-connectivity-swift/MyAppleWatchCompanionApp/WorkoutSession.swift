//
//  WorkoutSession.swift
//  MyAppleWatchCompanionApp
//

import HealthKit
import WatchKit

// MARK: - Workout session management
//
extension WorkoutManager {
    func startWorkout(workoutConfiguration: HKWorkoutConfiguration) async throws {
        guard sessionState == .notStarted else {
            print("Workout is already started or in progress.")
            return
        }

        session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        session?.delegate = self
        session?.startActivity(with: Date())
        
        WKInterfaceDevice.current().play(.success)
        sessionState = .running
    }
}
