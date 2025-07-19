//
//  ExhaleGUIAppApp.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//
import SwiftUI
import Foundation

@main
struct ExhaleGUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(TitleBarWindowStyle())
        
        Settings {
            SettingsView()
        }
    }
}
