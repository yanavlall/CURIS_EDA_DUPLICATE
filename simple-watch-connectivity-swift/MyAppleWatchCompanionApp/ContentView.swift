//
//  ContentView.swift
//  MyAppleWatchCompanionApp
//

import SwiftUI
import WatchConnectivity
import WatchKit
import Combine

struct ContentView: View {
    @ObservedObject var watchSession = WatchSession.shared
    
    @State var dataValue = ""
    
    var body: some View {
        VStack {
            Image("support")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: WKInterfaceDevice.current().screenBounds.width, height: WKInterfaceDevice.current().screenBounds.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onReceive(
            Just(watchSession.receivedData).delay(for: 1, scheduler: RunLoop.main)
        ) { newValue in
            self.dataValue = watchSession.receivedData
        }
    }
}
