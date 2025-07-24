//
//  DropZoneView.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//
import SwiftUI
import Foundation
import UniformTypeIdentifiers  // for UTType

// DropZoneView.swift - Drag and Drop Interface
struct DropZoneView: View {
    @Binding var isDragOver: Bool
    let onDrop: ([URL]) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 60))
                .foregroundColor(isDragOver ? .blue : .gray)
            
            VStack(spacing: 8) {
                Text("Drop audio files here")
                    .font(.headline)
                Text("Supports: WAV, MP3, FLAC, mp4, M4A, AAC")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("or click 'Add Files' to browse")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDragOver ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        let group = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                defer { group.leave() }
                
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                }
            }
        }
        
        group.notify(queue: .main) {
            let audioFiles = urls.filter { url in
                let ext = url.pathExtension.lowercased()
                return ["wav", "wave", "mp3", "flac", "mp4", "m4a", "aac"].contains(ext)
            }
            onDrop(audioFiles)
        }
    }
}

// MARK: - URL Extensions (add to this file)
extension URL {
    var isWAVFile: Bool {
        let ext = pathExtension.lowercased()
        return ext == "wav" || ext == "wave"
    }
    
    // Added helper to check if input is MP4
    var isMP4File: Bool {
        let ext = pathExtension.lowercased()
        return ext == "mp4"
    }
    
    var outputM4AURL: URL {
        return deletingPathExtension().appendingPathExtension("m4a")
    }
    
    // Helper to get a safe output URL that won't override the input
    var safeOutputM4AURL: URL {
        let baseURL = deletingPathExtension()
        let inputExt = pathExtension.lowercased()
        
        // If input is already .m4a, add suffix to avoid override
        if inputExt == "m4a" {
            return baseURL.appendingPathExtension("converted.m4a")
        } else {
            // For other formats (including mp4), just change extension to .m4a
            return baseURL.appendingPathExtension("m4a")
        }
    }
}

