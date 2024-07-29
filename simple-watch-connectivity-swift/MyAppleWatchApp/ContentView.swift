//
//  ContentView.swift
//  MyAppleWatchApp
//

import SwiftUI
import WatchConnectivity
import os
import HealthKitUI
import HealthKit

struct ContentView: View {
    @ObservedObject var watchConnectivityManager = WatchConnectivityManager.shared
    @ObservedObject var e4linkManager = E4linkManager.shared
    @ObservedObject var dataManager = DataManager.shared
    @State var showDisconnectAlert = false
    //@State var showDisconnectedAlert = false
    @State var showDeleteAlert = false
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var triggerAuthorization = false
    
    var screenWidth = UIScreen.main.bounds.size.width
    var screenHeight = UIScreen.main.bounds.size.height

    var body: some View {
        ScrollView {
            HStack(alignment: .firstTextBaseline) {
                Text("Devices")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .font(.title3)
                Spacer()
                Button(action: {
                    e4linkManager.restartDiscovery()
                }) {
                    Text("Rediscover")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(Color(red: 0.13333333333, green: 0.43921568627, blue: 0.70980392156))
                        .cornerRadius(15)
                        .font(Font.system(.footnote, design: .rounded))
                }
            }.padding(.horizontal, 20)
            
            Section {
                ForEach(e4linkManager.devices, id: \.serialNumber) { device in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(device.name)")
                                .font(.footnote)
                                .foregroundColor(.white)
                                .fontWeight(.heavy)
                            Text("Serial Number: \(device.serialNumber)")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("Status: \(e4linkManager.deviceStatus)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        /*.onChange(of: e4linkManager.deviceStatus) { oldState, newState in
                            if newState == "Disconnected" {
                                showDisconnectedAlert = true
                            }
                        }
                        .alert(isPresented: $showDisconnectedAlert) {
                            Alert(
                                title: Text("Device Disconnected"),
                                message: Text("\(device.name ?? "") has been disconnected. Rediscovering..."),
                                dismissButton: .default(Text("OK"))
                            )
                        }*/
                        Spacer()
                        Button(action: {
                            e4linkManager.select(device: device)
                        }) {
                            if (e4linkManager.deviceStatus == "Disconnected") {
                                Text("Connect")
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 20)
                                    .foregroundColor(.white)
                                    .background(Color(red: 0.13333333333, green: 0.43921568627, blue: 0.70980392156).opacity(0.5))
                                    .cornerRadius(25)
                                    .font(Font.system(.footnote, design: .rounded))
                            } else if (e4linkManager.deviceStatus == "Connected") {
                                Text("Disconnect")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 20)
                                    .foregroundColor(.white)
                                    .background(Color(red: 0.13333333333, green: 0.43921568627, blue: 0.70980392156).opacity(0.5))
                                    .cornerRadius(25)
                                    .font(Font.system(.footnote, design: .rounded))
                            }
                            
                        }
                    }
                    .alert(isPresented: $showDisconnectAlert) {
                        Alert(
                            title: Text("Disconnect from E4 Device"),
                            message: Text("Are you sure you want to disconnect?"),
                            primaryButton: .destructive(Text("Yes"), action: {
                                e4linkManager.select(device: device)
                                showDisconnectAlert = false
                            }),
                            secondaryButton: .default(Text("No"))
                        )
                    }
                    .padding(.horizontal, 20)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text("Files")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .font(.title3)
                Spacer()
                Button(action: {
                    dataManager.reloadFiles()
                }) {
                    Text("↻")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundColor(.white)
                        .background(Color(red: 0.13333333333, green: 0.43921568627, blue: 0.70980392156))
                        .cornerRadius(100)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Section {
                ForEach(Array(dataManager.files.enumerated()), id: \.element) { index, file in
                    HStack {
                        Text(file.lastPathComponent)
                            .font(.footnote)
                            .foregroundColor(.white)
                        Spacer()
                        ShareLink(item: file) {
                            Label("", systemImage:  "square.and.arrow.up")
                        }
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Text("❌")
                                .padding(.horizontal, 8.5)
                                .padding(.vertical, 10)
                                .foregroundColor(.white)
                                .background(Color(red: 0.13333333333, green: 0.43921568627, blue: 0.70980392156).opacity(0.5))
                                .cornerRadius(25)
                                .font(.system(.caption, design: .rounded))
                        }
                        .alert(isPresented: $showDeleteAlert) {
                            Alert(
                                title: Text("Delete Session Files"),
                                message: Text("Are you sure you want to delete?"),
                                primaryButton: .destructive(Text("Yes"), action: {
                                    dataManager.deleteFile(at: index)
                                    showDeleteAlert = false
                                }),
                                secondaryButton: .default(Text("No"))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 5)
                }
            }
            HStack(spacing: 20) {
                Button(action: {
                    watchConnectivityManager.sendDataFromPhone()
                }) {
                    Text("Send Data")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(Color(red: 0.13333333333, green: 0.43921568627, blue: 0.70980392156))
                        .cornerRadius(15)
                        .font(Font.system(.footnote, design: .rounded))
                }
                
                Button(action: {
                    watchConnectivityManager.sendDataFromPhonePt2()
                }) {
                    Text("Send Data Pt. 2")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(Color(red: 0.13333333333, green: 0.43921568627, blue: 0.70980392156))
                        .cornerRadius(15)
                        .font(Font.system(.footnote, design: .rounded))
                }
            }.padding(.vertical, 40)
            
            Button(action: {
                if !workoutManager.sessionState.isActive {
                    Task {
                        do {
                            try await workoutManager.startWatchWorkout(workoutType: .cycling)
                        } catch {
                            print("Failed to start cycling on the paired watch.")
                        }
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    print("DISPATCHED")
                    workoutManager.resetWorkout()
                }
                
            }) {
                Text("Start Workout")
            }
            .healthDataAccessRequest(store: workoutManager.healthStore,
                                     shareTypes: workoutManager.typesToShare,
                                     readTypes: workoutManager.typesToRead,
                                     trigger: triggerAuthorization,
                                     completion: { result in
                switch result {
                case .success(let success):
                    print("\(success) for authorization")
                case .failure(let error):
                    print("\(error) for authorization")
                }
            })
            .padding()
            
            Text("EDA Value: \(e4linkManager.absGSR)")
            Text("Threshold: \(Int(e4linkManager.threshold))")
            Text("List Length: \(e4linkManager.GSRList.count)")
            Text("Time: \(e4linkManager.current_index / e4linkManager.oneMinuteBufferSize) minute(s)")
            Text("Feature Flag: \(e4linkManager.featureDetected)")
        }
        .onAppear {
            e4linkManager.authenticate()
            dataManager.reloadFiles()
            triggerAuthorization.toggle()
        }
        .background(Color.black)
    }
}


