//
//  ContentView.swift
//  MyAppleWatchApp
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DevicesView()
                .tabItem {
                    Label("Devices", systemImage: "bolt.fill")
                }
            FilesView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }
        }
        .background(Color.black)
    }
}
