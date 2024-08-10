//
//  FilesView.swift
//  MyAppleWatchApp
//

import SwiftUI

struct FilesView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var workoutManager = WorkoutManager.shared
    @ObservedObject var watchConnectivityManager = WatchConnectivityManager.shared
    @State var showDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                fileListSection
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            dataManager.reloadFiles()
            workoutManager.requestAuthorization()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("Files")
                .foregroundColor(.black)
                .fontWeight(.bold)
                .font(.title3)
            Spacer()
            Button(action: {
                dataManager.reloadFiles()
            }) {
                Text("↻")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
    }
    
    // MARK: - File List Section
    private var fileListSection: some View {
        VStack(spacing: 15) {
            ForEach(Array(dataManager.files.enumerated()), id: \.element) { index, file in
                HStack {
                    Text(file.lastPathComponent)
                        .font(.footnote)
                        .foregroundColor(.black)
                    Spacer()
                    ShareLink(item: file) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Text("❌")
                            .padding(8)
                            .foregroundColor(.white)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(15)
                    }
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(
                            title: Text("Delete Session Files"),
                            message: Text("Are you sure you want to delete?"),
                            primaryButton: .destructive(Text("Yes"), action: {
                                dataManager.deleteFile(at: index)
                                showDeleteAlert = false
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
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                watchConnectivityManager.sendDataFromPhone()
            }) {
                Text("Send Data")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
        }
    }
}
