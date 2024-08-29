//
//  DevicesView.swift
//  MyAppleWatchApp
//

import SwiftUI

struct DevicesView: View {
    @ObservedObject var e4linkManager = E4linkManager.shared
    @ObservedObject var batteryMonitor = BatteryMonitor.shared
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
            print(batteryMonitor.batteryLevel)
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
                    .padding(14)
                    .foregroundColor(.white)
                    .background(Color.blue.opacity(0.5))
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
                        Text("Battery: \(e4linkManager.deviceStatus == "Disconnected" ? "n/a" : "\(e4linkManager.batteryLevel)%")")
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
                            .background(Color.blue)
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
                    Text("Threshold: \(e4linkManager.useManualThreshold ? e4linkManager.manualThreshold : e4linkManager.threshold)")
                    Text("Manual Threshold: \(e4linkManager.manualThreshold)")
                    Text("List Length: \(e4linkManager.GSRList.count)")
                    Text("Time: \(e4linkManager.current_index / e4linkManager.oneMinuteBufferSize) minute(s)")
                    Text("Feature Flag: \(e4linkManager.featureDetected)")
                    Toggle("Use Manual Threshold", isOn: $e4linkManager.useManualThreshold)
                    if e4linkManager.useManualThreshold {
                        HStack {
                            TextField("Enter new threshold", text: $thresholdInput)
                                .focused($isFocused)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .preferredColorScheme(.light)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        
                                        Button(action: { isFocused = false }) {
                                            Text("Dismiss")
                                                .foregroundColor(.blue)
                                                .font(.callout)
                                                .fontWeight(.bold)
                                        }
                                    }
                                }
                            Button(action: {
                                if thresholdInput.isEmpty {
                                    showThresholdAlert = true
                                } else {
                                    e4linkManager.manualThreshold = Float(thresholdInput) ?? e4linkManager.manualThreshold
                                    e4linkManager.objectWillChange.send()
                                    thresholdInput = ""
                                }
                                isFocused = false
                            }) {
                                Text("Set")
                                    .padding(10)
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
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

class BatteryMonitor: ObservableObject {
    static let shared = BatteryMonitor()

    @Published var batteryLevel: Float = 0.0
    
    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        self.batteryLevel = UIDevice.current.batteryLevel
        
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    }
    
    @objc func batteryLevelDidChange(notification: Notification) {
        self.batteryLevel = UIDevice.current.batteryLevel
        if (self.batteryLevel < 0.05 && E4linkManager.shared.didCollectData) {
            E4linkManager.shared.saveSession()
            E4linkManager.shared.notify(title: "iPhone Battery Low", body: "Session saved to prevent data loss. Please charge phone.", sound: "default")
        }
        print(self.batteryLevel)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    }
}
