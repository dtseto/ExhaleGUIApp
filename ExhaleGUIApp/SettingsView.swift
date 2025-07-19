//
//  SettingsView.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Main Settings View
struct SettingsView: View {
    var body: some View {
        TabView {
            ScrollView {
                GeneralSettingsTab()
                    .padding()
            }
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            
            ScrollView {
                AdvancedSettingsTab()
                    .padding()
            }
            .tabItem {
                Label("Advanced", systemImage: "slider.horizontal.3")
            }
        }
        .frame(width: 500, height: 400) // Keep this but content can scroll
    }
}

// MARK: - General Settings Tab
struct GeneralSettingsTab: View {
    @AppStorage("exhaleExecutablePath") private var exhaleExecutablePath = ""
    @AppStorage("outputQuality") private var outputQuality = "5" //string
    @AppStorage("preserveMetadata") private var preserveMetadata = true
    @AppStorage("deleteSourceFiles") private var deleteSourceFiles = false
    
    // Quality options
    private let qualityOptions = [
        ("0", "0 - ~48 stereo kbps (Lowest) <32khz sample rate"),
        ("1", "1 - ~64 kbps"),
        ("2", "2 - ~80 kbps"),
        ("3", "3 - ~96 kbps"),
        ("4", "4 - ~112 kbps"),
        ("5", "5 - ~128 kbps (Default)"),
        ("6", "6 - ~144 kbps"),
        ("7", "7 - ~160 kbps"),
        ("8", "8 - ~176 kbps"),
        ("9", "9 - ~192+ kbps (Highest quality)"),
        ("a", "a - ~36 stereo kbps (eSBR - Very low bitrate)"),
        ("b", "b - ~48 kbps (eSBR)"),
        ("c", "c - ~60 kbps (eSBR)"),
        ("d", "d - ~72 kbps (eSBR)"),
        ("e", "e - ~84 kbps (eSBR)"),
        ("f", "f - ~96 kbps (eSBR)"),
        ("g", "g - ~108 kbps (eSBR)")
    ]

    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Exhale Encoder Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Exhale Encoder")
                    .font(.headline)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Executable Path:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Path to exhale binary", text: $exhaleExecutablePath)
                            Button("Browse...") {
                                selectExhaleExecutable()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Quality Preset: \(outputQuality)")
                            
                            Picker("Quality", selection: $outputQuality) {
                                ForEach(qualityOptions, id: \.0) { option in
                                    Text(option.1).tag(option.0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            Text("0-9: Standard HE-AAC, a-g: eSBR (lower bitrate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            

            // Output Options Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Output Options")
                    .font(.headline)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Preserve metadata/ID tags (not working)", isOn: $preserveMetadata)
                        
                        HStack {
                            Toggle("Delete source files after conversion", isOn: $deleteSourceFiles)
                                .foregroundColor(deleteSourceFiles ? .red : .primary)
                            
                            if deleteSourceFiles {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
                        if deleteSourceFiles {
                            Text("⚠️ Warning: Original WAV files will be permanently deleted after successful conversion")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                    }
                    .padding()
                }
            }
            
            // Current Settings Summary
            VStack(alignment: .leading, spacing: 10) {
                Text("Current Settings")
                    .font(.headline)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Exhale Binary:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(exhaleExecutablePath.isEmpty ? "Not set" : exhaleExecutablePath.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(exhaleExecutablePath.isEmpty ? .red : .primary)
                        }
                        
                        HStack {
                            Text("Output Quality:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(outputQuality)/9")
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Output Format:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("M4A (AAC)")
                                .font(.caption)
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func selectExhaleExecutable() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Select Exhale Executable"
        panel.message = "Choose the exhale encoder binary"
        // macOS 11 compatible - don't set allowedFileTypes to empty string
        //panel.allowedFileTypes = nil  // Allow all files

        if panel.runModal() == .OK {
            if let url = panel.url {
                exhaleExecutablePath = url.path
            }
        }
    }
}

// MARK: - Advanced Settings Tab
struct AdvancedSettingsTab: View {
    @AppStorage("enableFdkAac") private var enableFdkAac = false
    @AppStorage("fdkAacPath") private var fdkAacPath = ""
    @AppStorage("tempDirectory") private var tempDirectory = ""
    @AppStorage("parallelConversions") private var parallelConversions = 2
    @AppStorage("showDetailedProgress") private var showDetailedProgress = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Future Extensions Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Future Extensions")
                    .font(.headline)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Enable FDK-AAC integration (coming soon)", isOn: $enableFdkAac)
                            .disabled(true) // TODO: Enable when implemented
                        
                        Text("This will allow converting MP3, FLAC, and other formats by first converting to WAV, then to AAC")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if enableFdkAac {
                            HStack {
                                Text("FDK-AAC Path:")
                                    .frame(width: 120, alignment: .leading)
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
            
            // Performance Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Performance")
                    .font(.headline)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Parallel Conversions: \(parallelConversions)")
                            Slider(value: Binding(
                                get: { Double(parallelConversions) },
                                set: { parallelConversions = Int($0) }
                            ), in: 1...8, step: 1)
                            
                            Text("Number of files to convert simultaneously (1-8)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Toggle("Show detailed progress information", isOn: $showDetailedProgress)
                        
                        Text("Note: More parallel conversions use more CPU and memory")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding()
                }
            }
            
            // System Section
            VStack(alignment: .leading, spacing: 10) {
                Text("System")
                    .font(.headline)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Temporary Directory:")
                                .frame(width: 120, alignment: .leading)
                            TextField("System default", text: $tempDirectory)
                            Button("Browse...") {
                                selectTempDirectory()
                            }
                        }
                        
                        if tempDirectory.isEmpty {
                            Text("Using system default temporary directory")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Custom: \(tempDirectory)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Reset to System Default") {
                            tempDirectory = ""
                        }
                        .disabled(tempDirectory.isEmpty)
                    }
                    .padding()
                }
            }
            
            Button("Test Bundled FFmpeg") {
                testBundledFFmpeg()
            }

            
            // Debug Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Debug & Information")
                    .font(.headline)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("macOS Version:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(ProcessInfo.processInfo.operatingSystemVersionString)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("CPU Cores:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(ProcessInfo.processInfo.processorCount)")
                                .font(.caption)
                        }
                        
                        Button("Test Exhale Binary") {
                            testExhaleBinary()
                        }
                        .disabled(UserDefaults.standard.string(forKey: "exhaleExecutablePath")?.isEmpty ?? true)
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func getBundledFFmpegPath() -> String? {
        guard let path = Bundle.main.path(forResource: "ffmpeg", ofType: nil) else {
            print("❌ FFmpeg not found in app bundle")
            return nil
        }
        
        // Verify it exists and is executable
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path),
              fileManager.isExecutableFile(atPath: path) else {
            print("❌ FFmpeg not executable in bundle")
            return nil
        }
        
        print("✅ Found bundled FFmpeg at: \(path)")
        return path
    }

    // Also add the missing showAlert function
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }

    
    private func selectTempDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select Temporary Directory"
        panel.message = "Choose a directory for temporary files during conversion"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                tempDirectory = url.path
            }
        }
    }
    
    private func testBundledFFmpeg() {
        guard let ffmpegPath = getBundledFFmpegPath() else {
            showAlert(title: "❌ FFmpeg Not Found", message: "FFmpeg not found in app bundle")
            return
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: ffmpegPath)
        task.arguments = ["-version"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""
                
                showAlert(
                    title: "✅ FFmpeg Working",
                    message: "Bundled FFmpeg is working!\n\nArchitectures: Universal (x86_64 + arm64)\n\n\(output.components(separatedBy: "\n").prefix(3).joined(separator: "\n"))"
                )
            } else {
                showAlert(title: "❌ FFmpeg Test Failed", message: "FFmpeg returned error code \(task.terminationStatus)")
            }
            
        } catch {
            showAlert(title: "❌ Cannot Execute FFmpeg", message: "Error: \(error.localizedDescription)")
        }
    }

    
    private func testExhaleBinary() {
        let exhalePath = UserDefaults.standard.string(forKey: "exhaleExecutablePath") ?? ""
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: exhalePath)
        task.arguments = ["--help"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let alert = NSAlert()
            alert.messageText = "Exhale Binary Test"
            alert.informativeText = task.terminationStatus == 0 ?
                "✅ Exhale binary is working correctly!" :
                "❌ Exhale binary test failed. Check the path and permissions."
            alert.alertStyle = task.terminationStatus == 0 ? .informational : .warning
            alert.runModal()
            
        } catch {
            let alert = NSAlert()
            alert.messageText = "Exhale Binary Test Failed"
            alert.informativeText = "Could not execute exhale binary: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.runModal()
        }
    }
}

// MARK: - Extensions for String Path Handling
private extension String {
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
}
