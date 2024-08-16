//
//  ContentView.swift
//  MyAppleWatchCompanionApp
//

import SwiftUI
import WatchConnectivity
import Combine

struct ContentView: View {
    @ObservedObject var workoutManager = WorkoutManager.shared
    @ObservedObject var watchSession = WatchSession.shared
    
    @State var dataValue = ""
    
    var body: some View {
        VStack {
            /*Text(dataValue)
                .fontWeight(.semibold)
                .padding()
            
            Text("Notification!")
                .fontWeight(.semibold)*/
            Image("support")
        }
        .onAppear {
            workoutManager.requestAuthorization()
        }
        .onReceive(
            Just(watchSession.receivedData).delay(for: 1, scheduler: RunLoop.main)
        )
        { newValue in
            self.dataValue = watchSession.receivedData
        }
    }
}
