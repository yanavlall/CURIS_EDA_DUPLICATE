//
//  ContentView.swift
//  MyAppleWatchCompanionApp
//

import SwiftUI
import WatchConnectivity
import Combine

struct ContentView: View {
    @ObservedObject var watchSession = WatchSession()
    
    // Variable to put the data value.
    @State private var textValue = ""
    
    var body: some View {
        // Text to show the data.
        Text(textValue)
            // Set data when received.
            .onReceive(
                Just(watchSession.receivedData).delay(
                        for: 1,
                        scheduler: RunLoop.main
                    )
            )
            { newValue in
                // Set text value.
                self.textValue = watchSession.receivedData
                
            }
    }
}

#Preview {
    ContentView()
}
