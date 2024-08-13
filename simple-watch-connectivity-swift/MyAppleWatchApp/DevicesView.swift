//
//  DevicesView.swift
//  MyAppleWatchApp
//

import SwiftUI

struct DevicesView: View {
    @ObservedObject var e4linkManager = E4linkManager.shared
    @State var showDisconnectAlert = false
    @State var thresholdInput: String = ""
    @State var showThresholdAlert = false
    @FocusState var isFocused: Bool
    @State var isFirstAppear = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                deviceListSection
                deviceDetailsSection
                surveyButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .sheet(isPresented: $e4linkManager.showSurvey) {
                SurveyView(survey: SampleSurvey, delegate: SceneDelegate()).preferredColorScheme(.light)
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            if (!isFirstAppear) {
                e4linkManager.authenticate()
                Task {
                    do {
                        try await e4linkManager.load()
                    } catch {
                        fatalError(error.localizedDescription)
                    }
                }
                isFirstAppear = true
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("Devices")
                .foregroundColor(.black)
                .fontWeight(.bold)
                .font(.title3)
            Spacer()
            Button(action: {
                e4linkManager.restartDiscovery()
            }) {
                Text("Rediscover")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
    }
    
    // MARK: - Device List Section
    private var deviceListSection: some View {
        VStack(spacing: 15) {
            ForEach(e4linkManager.devices, id: \.serialNumber) { device in
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(device.name)
                            .font(.footnote)
                            .fontWeight(.heavy)
                            .foregroundColor(.black)
                        Text("Serial Number: \(device.serialNumber)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Status: \(e4linkManager.deviceStatus)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Battery: \(e4linkManager.deviceStatus == "Disconnected" ? "n/a" : "\(e4linkManager.batteryLevel)")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        if e4linkManager.deviceStatus == "Disconnected" {
                            e4linkManager.select(device: device)
                        } else {
                            showDisconnectAlert = true
                        }
                    }) {
                        Text(e4linkManager.deviceStatus == "Disconnected" ? "Connect" : "Disconnect")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue.opacity(0.5))
                            .cornerRadius(15)
                            .font(Font.system(.footnote, design: .rounded))
                    }
                    .alert(isPresented: $showDisconnectAlert) {
                        Alert(
                            title: Text("Disconnect from E4 Device"),
                            message: Text("Are you sure you want to disconnect?"),
                            primaryButton: .destructive(Text("Yes"), action: {
                                e4linkManager.select(device: device)
                                showDisconnectAlert = false
                            }),
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Device Details Section
    private var deviceDetailsSection: some View {
        Group {
            if e4linkManager.deviceStatus == "Connected" {
                VStack(alignment: .leading, spacing: 10) {
                    Text("EDA Value: \(e4linkManager.absGSR)")
                    Text("Default Threshold: 3.0")
                    Text("Unique Threshold: \(e4linkManager.threshold)")
                    Text("List Length: \(e4linkManager.GSRList.count)")
                    Text("Time: \(e4linkManager.current_index / e4linkManager.oneMinuteBufferSize) minute(s)")
                    Text("Feature Flag: \(e4linkManager.featureDetected)")
                    
                    HStack {
                        TextField("Enter new threshold", text: $thresholdInput)
                            .focused($isFocused)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .cornerRadius(10)
                            .padding(5)
                            .foregroundStyle(.white, .white)
                        Button(action: {
                            if thresholdInput.isEmpty {
                                showThresholdAlert = true
                            } else {
                                e4linkManager.threshold = Float(thresholdInput) ?? e4linkManager.threshold
                            }
                            isFocused = false
                        }) {
                            Text("Set")
                                .padding(15)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                        .alert(isPresented: $showThresholdAlert) {
                            Alert(
                                title: Text("Input Error"),
                                message: Text("Please enter a valid threshold value."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.black)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Survey Button
    private var surveyButton: some View {
        HStack(spacing: 20) {
            if e4linkManager.showSurveyButton {
                Button(action: {
                    e4linkManager.showSurvey = true
                }) {
                    Text("Show Survey")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                }
            }
        }
    }
}
