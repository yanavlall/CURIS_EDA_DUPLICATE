//
//  ContentView.swift
//  MyAppleWatchCompanionApp
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        Text("Notification!")
            .fontWeight(.semibold)
            .onAppear {
                workoutManager.requestAuthorization()
            }
    }
    
}

