//
//  AdvancedSettingsView.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//
import SwiftUI
import Foundation

// AdvancedSettingsView.swift - Advanced Settings (macOS 11 Compatible)
struct AdvancedSettingsView: View {
    @AppStorage("enableFdkAac") private var enableFdkAac = false
    @AppStorage("fdkAacPath") private var fdkAacPath = ""
    @AppStorage("tempDirectory") private var tempDirectory = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Future Extensions Section - macOS 11 Compatible
            VStack(alignment: .leading, spacing: 10) {
                Text("Future Extensions")
                    .font(.headline)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Enable FDK-AAC integration (coming soon)", isOn: $enableFdkAac)
                            .disabled(true) // TODO: Enable when implemented
                        
                        if enableFdkAac {
                            HStack {
                                Text("FDK-AAC Path:")
                                TextField("Path to fdk-aac-enc", text: $fdkAacPath)
                                    .disabled(true)
                                Button("Browse...") {
                                    // TODO: Implement
                                }
                                .disabled(true)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // System Section - macOS 11 Compatible
            VStack(alignment: .leading, spacing: 10) {
                Text("System")
                    .font(.headline)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Temporary Directory:")
                            TextField("System default", text: $tempDirectory)
                            Button("Browse...") {
                                selectTempDirectory()
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func selectTempDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                tempDirectory = url.path
            }
        }
    }
}
