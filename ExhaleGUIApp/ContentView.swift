//
//  ContentView.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var audioConverter = AudioConverter()
    @State private var isDragOver = false
    @State private var showingFilePicker = false
    
    // Add this computed property to ContentView
    private var conversionSummary: String {
        let total = audioConverter.conversionItems.count
        let completed = audioConverter.conversionItems.filter { $0.status == .completed }.count
        let converting = audioConverter.conversionItems.filter { $0.status == .converting }.count
        let failed = audioConverter.conversionItems.filter { $0.status == .failed }.count
        
        if audioConverter.isConverting {
            return "Converting \(converting) of \(total) files... (\(completed) done, \(failed) failed)"
        } else {
            return "\(total) files total - \(completed) completed, \(failed) failed"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Exhale Audio Converter")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Convert WAV files to high-quality AAC/MP4")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Settings (disabled click in menu)") {
                    if #available(macOS 14.0, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else if #available(macOS 13.0, *) {
                        NSApp.sendAction(Selector(("showPreferences:")), to: nil, from: nil)
                    } else {
                        // Fallback for older macOS
                        NSApp.activate(ignoringOtherApps: true)
                        for window in NSApp.windows {
                            if window.title.contains("Settings") || window.title.contains("Preferences") {
                                window.makeKeyAndOrderFront(nil)
                                return
                            }
                        }
                        NSApp.sendAction(Selector(("showPreferences:")), to: nil, from: nil)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            
            // Drop Zone
            DropZoneView(isDragOver: $isDragOver) {
                audioConverter.addFiles($0)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDragOver ? Color.blue : Color.gray.opacity(0.3),
                           style: StrokeStyle(lineWidth: 2, dash: [10]))
            )
            
            // File List and Progress
            if !audioConverter.conversionItems.isEmpty {
                ConversionListView(audioConverter: audioConverter)
                    .frame(maxHeight: 300)
            }
            
            // Controls and Status
            VStack(spacing: 10) {
                // Status Display
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(conversionSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if audioConverter.isConverting {
                            let activeConversions = audioConverter.conversionItems.filter { $0.status == .converting }.count
                            Text("\(activeConversions) files converting simultaneously")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Control Buttons
                HStack {
                    Button("Add Files") {
                        showingFilePicker = true
                    }
                    .disabled(audioConverter.isConverting)
                    
                    Spacer()
                    
                    Button("Clear All") {
                        audioConverter.clearAll()
                    }
                    .disabled(audioConverter.isConverting)
                    
                    Button(audioConverter.isConverting ? "Cancel" : "Convert All") {
                        if audioConverter.isConverting {
                            audioConverter.cancelConversion()
                        } else {
                            audioConverter.startConversion()
                        }
                    }
                    .disabled(audioConverter.conversionItems.isEmpty)
                    .buttonStyle(ProminentButtonStyle())
                }
                .padding()
            }
            
            Spacer()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.wav, .audio],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                audioConverter.addFiles(urls)
            case .failure(let error):
                print("File selection error: \(error)")
            }
        }
    }
}

// MARK: - Custom Button Style for macOS 11
struct ProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
