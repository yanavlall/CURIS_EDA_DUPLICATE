//
//  FilesView.swift
//  MyAppleWatchApp
//

import SwiftUI

struct FilesView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var watchConnectivityManager = WatchConnectivityManager.shared
    @State var showSurveyAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            fileListSection
            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 40) // Adjust padding to move the content up
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            dataManager.reloadFiles()
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
                    .background(Color.blue.opacity(0.5))
                    .clipShape(.circle)
            }
        }
    }
    
    // MARK: - File List Section
    private var fileListSection: some View {
        List {
            ForEach(Array(dataManager.files.enumerated()), id: \.element) { index, file in
                HStack {
                    Text("  " + file.lastPathComponent)
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Spacer()
                    ShareLink(item: file) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteFile(at: IndexSet(integer: index))
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(InsetListStyle())
        .environment(\.defaultMinListRowHeight, UIScreen.main.bounds.height / 15)
        .preferredColorScheme(.light)
        .ignoresSafeArea(.all)
        .padding(.trailing, 10)
    }

    // Function to delete the file
    private func deleteFile(at offsets: IndexSet) {
        for index in offsets {
            dataManager.deleteFile(at: index)
        }
    }

    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 20) {
            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("SurveyResponses.csv").path) {
                ShareLink(item: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("SurveyResponses.csv")) {
                    Text("Export Surveys")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                }
            } else {
                Button(action: {
                    showSurveyAlert = true
                }) {
                    Text("Export Surveys")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(15)
                }
            }
        }
        .alert(isPresented: $showSurveyAlert) {
            Alert(
                title: Text("No Survey Data"),
                message: Text("Please take a survey to export this file."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
