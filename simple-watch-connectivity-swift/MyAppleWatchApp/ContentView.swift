//
//  ContentView.swift
//  MyAppleWatchApp
//

import SwiftUI
import WatchConnectivity
    
struct ContentView: View {
    @ObservedObject var watchConnectivityManager = WatchConnectivityManager.shared
    @ObservedObject var e4linkManager = E4linkManager.shared

    var body: some View {
        NavigationView {
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
                List(e4linkManager.devices, id: \.serialNumber) { device in
                    VStack(alignment: .leading) {
                        Text("Device: \(device.name)")
                            .font(.headline)
                        Text("Serial Number: \(device.serialNumber)")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Devices")
        .onAppear {
            e4linkManager.authenticate()
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

