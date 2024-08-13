//
//  FilesView.swift
//  MyAppleWatchApp
//

import SwiftUI

struct FilesView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var workoutManager = WorkoutManager.shared
    @ObservedObject var watchConnectivityManager = WatchConnectivityManager.shared
    @State var showSessionDeleteAlert = false
    @State var showSurveyDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                sessionFileSection
                surveyFileSection
                Spacer()
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
    
    // MARK: - Session File Section
    private var sessionFileSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sessions")
                .foregroundColor(.black)
                .fontWeight(.bold)
                .font(.subheadline)
            ForEach(Array(dataManager.sessionFiles.enumerated()), id: \.element) { index, file in
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
                        showSessionDeleteAlert = true
                    }) {
                        Text("❌")
                            .padding(8)
                            .foregroundColor(.white)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(15)
                    }
                    .alert(isPresented: $showSessionDeleteAlert) {
                        Alert(
                            title: Text("Delete Session Files"),
                            message: Text("Are you sure you want to delete?"),
                            primaryButton: .destructive(Text("Yes"), action: {
                                dataManager.deleteFile(at: index, type: "session")
                                showSessionDeleteAlert = false
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
    
    // MARK: - Survey File Section
    private var surveyFileSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Surveys")
                .foregroundColor(.black)
                .fontWeight(.bold)
                .font(.subheadline)
            ForEach(Array(dataManager.surveyFiles.enumerated()), id: \.element) { index, file in
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
                        showSurveyDeleteAlert = true
                    }) {
                        Text("❌")
                            .padding(8)
                            .foregroundColor(.white)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(15)
                    }
                    .alert(isPresented: $showSurveyDeleteAlert) {
                        Alert(
                            title: Text("Delete Survey Files"),
                            message: Text("Are you sure you want to delete?"),
                            primaryButton: .destructive(Text("Yes"), action: {
                                dataManager.deleteFile(at: index, type: "survey")
                                showSurveyDeleteAlert = false
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
