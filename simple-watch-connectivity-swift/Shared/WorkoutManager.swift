//
//  WorkoutManager.swift
//  MyAppleWatchApp
//
//  A class that wraps the data and operations related to workout.

import Foundation
import os
import HealthKit

@MainActor
class WorkoutManager: NSObject, ObservableObject {
    @Published var sessionState: HKWorkoutSessionState = .notStarted
    @Published var workout: HKWorkout?
    /**
     HealthKit data types to share and read.
     */
    let typesToShare: Set = [HKQuantityType.workoutType()]
    let typesToRead: Set = [HKQuantityType.workoutType()]
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    /**
     WorkoutManager is a singleton.
     */
    static let shared = WorkoutManager()
}

// MARK: - Workout session management
//
extension WorkoutManager {
    func resetWorkout() {
        print("RESET")
        session = nil
        sessionState = .notStarted
        
        #if os(watchOS)
        print("END SESSION")
        session?.end()
        #endif
    }
}


// MARK: - HKWorkoutSessionDelegate
// HealthKit calls the delegate methods on an anonymous serial background queue,
// so the methods need to be nonisolated explicitly.
//
extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        print("Session state changed from \(fromState.rawValue) to \(toState.rawValue)")
    }
        
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didFailWithError error: Error) {
        print("\(#function): \(error)")
    }
    
    /**
     HealthKit calls this method when it determines that the mirrored workout session is invalid.
     */
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didDisconnectFromRemoteDeviceWithError error: Error?) {
        print("\(#function): \(String(describing: error))")
    }
    
    /**
     In iOS, the sample app can go into the background and become suspended.
     When suspended, HealthKit gathers the data coming from the remote session.
     When the app resumes, HealthKit sends an array containing all the data objects it has accumulated to this delegate method.
     The data objects in the array appear in the order that the local system received them.
     
     On watchOS, the workout session keeps the app running even if it is in the background; however, the system can
     temporarily suspend the app — for example, if the app uses an excessive amount of CPU in the background.
     While suspended, HealthKit caches the incoming data objects and delivers an array of data objects when the app resumes, just like in the iOS app.
     */
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        print("\(#function): \(data.debugDescription)")
    }
}


// MARK: - Convenient workout state
//
extension HKWorkoutSessionState {
    var isActive: Bool {
        self != .notStarted && self != .ended
    }
}
