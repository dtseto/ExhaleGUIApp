//
//  Models.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//

import Foundation
import SwiftUI

// MARK: - ConversionItem Data Model
class ConversionItem: ObservableObject, Identifiable {
    let id = UUID()
    let inputURL: URL
    @Published var outputURL: URL?
    @Published var status: ConversionStatus = .pending
    @Published var progress: Double = 0
    @Published var errorMessage: String?
    
    var fileSize: Int64? {
        try? inputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init)
    }
    
    init(inputURL: URL) {
        self.inputURL = inputURL
    }
}

// MARK: - Conversion Status
enum ConversionStatus: CaseIterable {
    case pending
    case converting
    case completed
    case failed
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .converting: return "Converting..."
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .converting: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Conversion Errors
enum ConversionError: LocalizedError {
    case exhaleNotFound(String)
    case inputFileNotFound(String)
    case conversionFailed(String)
    case ffmpegNotFound(String)  // Add this
    
    var errorDescription: String? {
        switch self {
        case .exhaleNotFound(let message):
            return message
        case .inputFileNotFound(let message):
            return message
        case .conversionFailed(let message):
            return message
        case .ffmpegNotFound(let message):  // Add this
            return message
        }
    }
}
