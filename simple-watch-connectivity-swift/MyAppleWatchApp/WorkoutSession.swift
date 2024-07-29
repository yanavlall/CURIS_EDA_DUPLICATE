//
//  WorkoutSession.swift
//  MyAppleWatchApp
//

import Foundation
import os
import HealthKit

// MARK: - Workout session management
//
extension WorkoutManager {
    func startWatchWorkout(workoutType: HKWorkoutActivityType) async throws {
        print("START WORKOUT")
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        try await healthStore.startWatchApp(toHandle: configuration)
    }
}
