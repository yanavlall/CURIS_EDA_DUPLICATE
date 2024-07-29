//
//  WorkoutSession.swift
//  MyAppleWatchCompanionApp
//

import Foundation
import os
import HealthKit
import WatchKit

// MARK: - Workout session management
//
extension WorkoutManager {
    /**
     Use healthStore.requestAuthorization to request authorization in watchOS when
     healthDataAccessRequest isn't available yet.
     */
    func requestAuthorization() {
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            } catch {
                print("Failed to request authorization: \(error).")
            }
        }
    }
    
    func startWorkout(workoutConfiguration: HKWorkoutConfiguration) async throws {
        session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        session?.delegate = self
        session?.startActivity(with: Date())
        
        WKInterfaceDevice.current().play(.success)
    }
}
