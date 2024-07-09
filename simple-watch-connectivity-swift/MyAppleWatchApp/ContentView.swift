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
                Button(action: {
                    e4linkManager.restartDiscovery()
                }) {
                    Text("Restart Discovery")
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
                        Text("Status: \(e4linkManager.deviceStatusDisplay(status: device.deviceStatus))")
                            .font(.subheadline)
                    }.onTapGesture {
                        e4linkManager.select(device: device)
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

