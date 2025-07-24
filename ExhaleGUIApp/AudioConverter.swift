//
//  AudioConverter.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//

import Foundation
import Combine
import SwiftUI

import AVFoundation

class AudioConverter: ObservableObject {
    @Published var conversionItems: [ConversionItem] = []
    @Published var isConverting = false
    
    private var conversionTask: Process?
    private var cancellables = Set<AnyCancellable>()
    
    func addFiles(_ urls: [URL]) {
        let newItems = urls.map { url in
            ConversionItem(inputURL: url)
        }
        conversionItems.append(contentsOf: newItems)
    }
    
    func removeItems(at offsets: IndexSet) {
        conversionItems.remove(atOffsets: offsets)
    }
    
    func clearAll() {
        guard !isConverting else { return }
        conversionItems.removeAll()
    }
    
    func startConversion() {
        guard !isConverting && !conversionItems.isEmpty else { return }
        
        isConverting = true
        
        Task {
            // Get parallel conversion setting
            let maxConcurrent = UserDefaults.standard.integer(forKey: "parallelConversions")
            let actualConcurrent = maxConcurrent > 0 ? maxConcurrent : 2
            
            print("🚀 Starting parallel conversion with max \(actualConcurrent) concurrent tasks")
            
            // Get pending items
            let pendingItems = conversionItems.filter { $0.status == .pending }
            
            await withTaskGroup(of: Void.self) { group in
                var activeCount = 0
                var itemIndex = 0
                
                // Start initial batch
                while activeCount < actualConcurrent && itemIndex < pendingItems.count {
                    let item = pendingItems[itemIndex]
                    group.addTask {
                        await self.convertItem(item)
                    }
                    activeCount += 1
                    itemIndex += 1
                }
                
                // As tasks complete, start new ones
                for await _ in group {
                    activeCount -= 1
                    
                    // Start next item if available
                    if itemIndex < pendingItems.count {
                        let item = pendingItems[itemIndex]
                        group.addTask {
                            await self.convertItem(item)
                        }
                        activeCount += 1
                        itemIndex += 1
                    }
                }
            }
            
            await MainActor.run {
                isConverting = false
                print("🏁 All conversions completed")
            }
        }
    }
    
    func cancelConversion() {
        conversionTask?.terminate()
        isConverting = false
        
        // Reset converting items to pending
        for item in conversionItems {
            if item.status == .converting {
                item.status = .pending
                item.progress = 0
            }
        }
    }
    
    @MainActor
    private func convertItem(_ item: ConversionItem) async {
        print("🎵 Starting conversion: \(item.inputURL.lastPathComponent)")
        item.status = .converting
        item.progress = 0
        
        // Use the safe output URL to prevent overwriting
        let outputURL = item.inputURL.safeOutputM4AURL

        do {
            let inputExt = item.inputURL.pathExtension.lowercased()
            
            if ["mp3", "flac", "m4a", "aac", "mp4"].contains(inputExt) {
                // Two-step conversion: MP3/FLAC → WAV → M4A
                print("📀 Multi-step conversion detected")
                
                let tempWAV = item.inputURL.appendingPathExtension("temp.wav")
                
                // Step 1: Convert to WAV
                item.progress = 0.1
                try await convertToWAV(inputURL: item.inputURL, outputURL: tempWAV)
                
                // Step 2: Convert WAV to M4A with Exhale
                item.progress = 0.5
                try await runExhaleConversion(
                    inputURL: tempWAV,
                    outputURL: outputURL,
                    progressCallback: { progress in
                        Task { @MainActor in
                            item.progress = 0.5 + (progress * 0.5) // 50-100%
                        }
                    }
                )
                
                // Clean up temp file
                try? FileManager.default.removeItem(at: tempWAV)
                
            } else {
                // Direct WAV → M4A conversion
                try await runExhaleConversion(
                    inputURL: item.inputURL,
                    outputURL: outputURL,
                    progressCallback: { progress in
                        Task { @MainActor in
                            item.progress = progress
                        }
                    }
                )
            }
            
            item.status = .completed
            item.outputURL = outputURL
            print("✅ Completed: \(item.inputURL.lastPathComponent)")

            
            
            // Handle metadata if enabled
            if UserDefaults.standard.bool(forKey: "preserveMetadata") {
                print("📋 Processing metadata for \(item.inputURL.lastPathComponent)")
                await copyMetadata(from: item.inputURL, to: outputURL)
            }
            
            // Delete source file if enabled
            if UserDefaults.standard.bool(forKey: "deleteSourceFiles") {
                try? FileManager.default.removeItem(at: item.inputURL)
                print("🗑️ Deleted source: \(item.inputURL.lastPathComponent)")
            }
            
        } catch {
            item.status = .failed
            item.errorMessage = error.localizedDescription
            print("❌ Failed: \(item.inputURL.lastPathComponent) - \(error)")
        }
    }
    private func runExhaleConversion(
        inputURL: URL,
        outputURL: URL,
        progressCallback: @escaping (Double) -> Void
    ) async throws {
        
        // Debug ALL quality-related UserDefaults
        print("=== QUALITY DEBUG ===")
        print("String quality: '\(UserDefaults.standard.string(forKey: "outputQuality") ?? "nil")'")
        print("Int quality: \(UserDefaults.standard.integer(forKey: "outputQuality"))")
        print("Object quality: \(UserDefaults.standard.object(forKey: "outputQuality") ?? "nil")")
        
        
        let exhalePathKey = "exhaleExecutablePath"
        let exhalePath = UserDefaults.standard.string(forKey: exhalePathKey) ?? ""
        let quality = UserDefaults.standard.string(forKey: "outputQuality") ?? "5"
        
        print("=== DETAILED EXHALE DEBUG ===")
        print("Raw exhale path: '\(exhalePath)'")
        print("Input file: '\(inputURL.path)'")
        print("Output file: '\(outputURL.path)'")
        print("Quality: \(quality)")
        
        // Step 1: Check if path is empty
        guard !exhalePath.isEmpty else {
            print("❌ ERROR: Exhale path is empty")
            throw ConversionError.exhaleNotFound("Exhale executable path not set. Please set it in Settings.")
        }
        
        // Step 2: Check if file exists
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: exhalePath)
        print("File exists check: \(fileExists)")
        
        if !fileExists {
            print("❌ ERROR: File does not exist at path: \(exhalePath)")
            
            // Let's check what IS in that directory
            let parentDir = (exhalePath as NSString).deletingLastPathComponent
            print("Checking parent directory: \(parentDir)")
            
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: parentDir)
                print("Directory contents: \(contents)")
            } catch {
                print("Could not read directory: \(error)")
            }
            
            throw ConversionError.exhaleNotFound("Exhale executable not found at: \(exhalePath)")
        }
        
        // Step 3: Check if file is executable
        let isExecutable = fileManager.isExecutableFile(atPath: exhalePath)
        print("Is executable: \(isExecutable)")
        
        if !isExecutable {
            print("❌ ERROR: File is not executable")
            //    throw ConversionError.exhaleNotFound("File is not executable: \(exhalePath)\n\nRun: chmod +x \"\(exhalePath)\"")
        }
        
        // Step 4: Get file attributes
        do {
            let attributes = try fileManager.attributesOfItem(atPath: exhalePath)
            print("File size: \(attributes[.size] ?? "unknown")")
            print("File permissions: \(attributes[.posixPermissions] ?? "unknown")")
            print("File type: \(attributes[.type] ?? "unknown")")
        } catch {
            print("Could not get file attributes: \(error)")
        }
        
        // Step 5: Check input file
        guard fileManager.fileExists(atPath: inputURL.path) else {
            print("❌ ERROR: Input file does not exist")
            throw ConversionError.inputFileNotFound("Input file not found: \(inputURL.path)")
        }
        
        print("✅ All file checks passed, attempting to start process...")
        
        // Step 6: Try to execute
        let process = Process()
        process.executableURL = URL(fileURLWithPath: exhalePath)
        // FIXED: Correct argument order - preset comes first!
        process.arguments = [
            "\(quality)",           // Preset first!
            inputURL.path,          // Input second
            outputURL.path          // Output third
        ]
        
        print("Correct command: \(exhalePath) \(quality) \"\(inputURL.path)\" \"\(outputURL.path)\"")
        
        // Set up pipes for output capture
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        conversionTask = process
        
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if let outputString = String(data: outputData, encoding: .utf8), !outputString.isEmpty {
                    print("Exhale stdout: \(outputString)")
                }
                
                if let errorString = String(data: errorData, encoding: .utf8), !errorString.isEmpty {
                    print("Exhale stderr: \(errorString)")
                    
                    if process.terminationStatus != 0 {
                        let userFriendlyError = self.parseExhaleError(errorString, quality: quality)
                        continuation.resume(throwing: ConversionError.conversionFailed(userFriendlyError))
                        return
                    }
                }
                
                if process.terminationStatus == 0 {
                    print("✅ Conversion completed successfully")
                    continuation.resume()
                } else {
                    let errorMsg = "Exhale failed with exit code \(process.terminationStatus)"
                    continuation.resume(throwing: ConversionError.conversionFailed(errorMsg))
                }
            }
            
            do {
                try process.run()
                print("✅ Exhale process started successfully")
                
                // Simple progress simulation
                Task {
                    var progress: Double = 0
                    while process.isRunning && progress < 1.0 {
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        progress += 0.1
                        await MainActor.run {
                            progressCallback(min(progress, 0.9))
                        }
                    }
                    if !process.isRunning {
                        await MainActor.run {
                            progressCallback(1.0)
                        }
                    }
                }
                
            } catch {
                print("❌ Failed to start exhale process: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func parseExhaleError(_ errorString: String, quality: String) -> String {
        let error = errorString.lowercased()
        
        if error.contains("input sample rate must be <=32 khz") {
            return """
            🚨 Sample Rate Too High for Preset \(quality)
            
            Your audio file has a sample rate higher than 32 kHz (probably 44.1 kHz).
            
            Solutions:
            • Use preset 1-9 or a-g (they support higher sample rates)
            • Preset 0 only works with ≤32 kHz audio files
            
            Recommended: Try preset '5' for good quality at normal bitrates.
            """
        }
        
        if error.contains("could not open input file") || error.contains("invalid wave file") {
            return """
            🚨 Invalid Input File
            
            The WAV file appears to be corrupted or in an unsupported format.
            
            Make sure:
            • File is a valid WAV/WAVE file
            • File is not corrupted or empty
            • File has standard PCM encoding
            """
        }
        
        if error.contains("could not create output file") || error.contains("permission denied") {
            return """
            🚨 Cannot Create Output File
            
            Check:
            • You have write permission to the output folder
            • Output file isn't already open in another app
            • There's enough disk space
            • Try saving to Downloads folder
            """
        }
        
        if error.contains("unsupported channel configuration") {
            return """
            🚨 Unsupported Audio Channels
            
            Exhale may not support this channel configuration.
            
            Supported:
            • Mono (1 channel)
            • Stereo (2 channels)
            • Some multichannel formats
            """
        }
        
        // Default error with helpful context
        return """
        🚨 Conversion Failed
        
        Raw error: \(errorString)
        
        Common solutions:
        • Try a different quality preset (1-9 or a-g)
        • Make sure input is a valid WAV file
        • Check file permissions
        • Try moving files to Downloads folder
        """
    }
    
    
    
    // Add this function to get bundled FFmpeg
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

    // Add this function for MP3 → WAV conversion
    private func convertToWAV(inputURL: URL, outputURL: URL) async throws {
        guard let ffmpegPath = getBundledFFmpegPath() else {
            throw ConversionError.ffmpegNotFound("FFmpeg not found in app bundle")
        }
        
        print("🔄 Converting \(inputURL.lastPathComponent) to WAV...")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = [
            "-i", inputURL.path,          // Input file
            "-ar", "44100",               // Sample rate
            "-ac", "2",                   // Stereo
            "-f", "wav",                  // WAV format
            "-y",                         // Overwrite output
            outputURL.path                // Output file
        ]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if let errorString = String(data: errorData, encoding: .utf8), !errorString.isEmpty {
                    print("FFmpeg output: \(errorString)")
                }
                
                if process.terminationStatus == 0 {
                    print("✅ WAV conversion completed")
                    continuation.resume()
                } else {
                    let errorMsg = "FFmpeg failed with exit code \(process.terminationStatus)"
                    continuation.resume(throwing: ConversionError.conversionFailed(errorMsg))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    
    
    
    // Replace your copyMetadata function with this simple, safe version:

    private func copyMetadata(from sourceURL: URL, to destinationURL: URL) async {
        guard UserDefaults.standard.bool(forKey: "preserveMetadata") else {
            print("Metadata preservation disabled")
            return
        }
        
        print("📋 Metadata preservation requested for \(sourceURL.lastPathComponent)")
        
        do {
            // Read source metadata
            let sourceAsset = AVURLAsset(url: sourceURL)
            let sourceMetadata = sourceAsset.metadata
            
            print("Found \(sourceMetadata.count) metadata items in source WAV file")
            
            // Log what metadata we found
            for item in sourceMetadata {
                if let key = item.commonKey {
                    
                    let valueString = item.stringValue ?? (item.value as? String) ?? "Unknown"
                    print("  Source metadata: \(key.rawValue) = \(valueString)")

                }
            }
            
            // Check if destination exists
            guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                print("❌ Destination M4A file not found")
                return
            }
            
            // For now, just add a simple comment to the file using string-based metadata
            let asset = AVURLAsset(url: destinationURL)
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
                print("❌ Could not create export session")
                return
            }
            
            // Create temporary file
            let tempURL = destinationURL.appendingPathExtension("temp")
            exportSession.outputURL = tempURL
            exportSession.outputFileType = .m4a
            
            // Create simple metadata using string identifiers (safer approach)
            var metadata: [AVMetadataItem] = []
            
            // Add title from filename
            let titleItem = AVMutableMetadataItem()
            titleItem.keySpace = .iTunes
            titleItem.key = "©nam" as NSString  // iTunes title key
            titleItem.value = sourceURL.deletingPathExtension().lastPathComponent as NSString
            metadata.append(titleItem)
            
            // Add encoder info
            let encoderItem = AVMutableMetadataItem()
            encoderItem.keySpace = .iTunes
            encoderItem.key = "©too" as NSString  // iTunes encoding tool key
            encoderItem.value = "ExhaleGUI + Exhale v1.2.1" as NSString
            metadata.append(encoderItem)
            
            exportSession.metadata = metadata
            
            await exportSession.export()
            
            if exportSession.status == .completed {
                // Replace original with metadata version
                try FileManager.default.removeItem(at: destinationURL)
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                print("✅ Basic metadata added successfully")
            } else {
                // Clean up and continue without metadata
                try? FileManager.default.removeItem(at: tempURL)
                print("⚠️ Metadata export failed, keeping original file: \(exportSession.error?.localizedDescription ?? "Unknown error")")
            }
            
        } catch {
            print("⚠️ Metadata copying failed, file conversion still successful: \(error.localizedDescription)")
        }
    }

    // Alternative: Even simpler version that just logs (no actual metadata writing)
    private func copyMetadataLog(from sourceURL: URL, to destinationURL: URL) async {
        guard UserDefaults.standard.bool(forKey: "preserveMetadata") else {
            print("Metadata preservation disabled")
            return
        }
        
        print("📋 Metadata preservation enabled for \(sourceURL.lastPathComponent)")
        
        // Read and log source metadata
        let sourceAsset = AVURLAsset(url: sourceURL)
        let sourceMetadata = sourceAsset.metadata
        
        print("Source file metadata:")
        if sourceMetadata.isEmpty {
            print("  No metadata found in source WAV file")
        } else {
            for item in sourceMetadata {
                if let key = item.commonKey?.rawValue {
                    let value = item.stringValue ?? item.value as? String ?? "Unknown"
                    print("  \(key): \(value)")
                }
            }
        }
        
        // Log what we would add
        let fileName = sourceURL.deletingPathExtension().lastPathComponent
        print("Would add to M4A file:")
        print("  Title: \(fileName)")
        print("  Encoder: ExhaleGUI + Exhale v1.2.1")
        
        // Check if output file exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("✅ M4A file created successfully (metadata logged)")
        } else {
            print("❌ M4A file not found")
        }
    }

    // Minimal version - just ensure file was created
    private func copyMetadataMinimal(from sourceURL: URL, to destinationURL: URL) async {
        guard UserDefaults.standard.bool(forKey: "preserveMetadata") else { return }
        
        // Just verify the conversion worked
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("📋 File converted successfully (metadata preservation noted)")
        }
        
        // Note: Full metadata writing requires more complex implementation
        // or external tools like AtomicParsley, Mp3tag, etc.
    }
}
