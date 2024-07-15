//
//  ContentView.swift
//  MyAppleWatchApp
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @ObservedObject var watchConnectivityManager = WatchConnectivityManager.shared
    @ObservedObject var e4linkManager = E4linkManager.shared
    @ObservedObject var dataManager = DataManager.shared
    @State var showAlert = false
    @State var showDeleteAlert = false
    
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
                        /*.onTapGesture {
                            e4linkManager.select(device: device)
                        }*/
                        .onChange(of: e4linkManager.deviceStatus) { oldState, newState in
                            if newState == "Disconnected" {
                                showAlert = true
                            }
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text("Device Disconnected"),
                                message: Text("\(device.name ?? "") has been disconnected. Rediscovering..."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                        Spacer()
                        Button(action: {
                            e4linkManager.select(device: device)
                        }) {
                            Text("Connect")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 20)
                                .foregroundColor(.white)
                                .background(Color(red: 0.13333333333, green: 0.43921568627, blue: 0.70980392156).opacity(0.5))
                                .cornerRadius(25)
                                .font(Font.system(.footnote, design: .rounded))
                        }
                    }.padding(.horizontal, 20)
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
                    //let nc = NotificationCenter.default
                    //nc.post(name: Notification.Name("UserLoggedIn"), object: nil)
                    //sendNotification(title: "Data Sent", body: "Second-type data sent to Apple Watch")
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
            }.padding(.top, 40)
        }
        .onAppear {
            e4linkManager.authenticate()
            dataManager.reloadFiles()
        }
        .background(Color.black)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

/*func sendNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default
    
    // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Not able to add notification: \(error.localizedDescription)")
            return
        }
    }
}*/
