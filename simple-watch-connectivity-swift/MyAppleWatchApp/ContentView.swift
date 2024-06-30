//
//  ContentView.swift
//  MyAppleWatchApp
//
//  Created by Katie Liu on 6/28/24.
//

import SwiftUI
import WatchConnectivity
    
struct ContentView: View {
    @ObservedObject var watchConnectivityManager = WatchConnectivityManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                watchConnectivityManager.sendDataFromPhone()
            }) {
                Text("Send Data")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                watchConnectivityManager.sendDataFromPhonePt2()
            }) {
                Text("Send Data Pt. 2")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

