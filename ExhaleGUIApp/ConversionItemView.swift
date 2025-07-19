//
//  ConversionItemView.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//
import SwiftUI
import Foundation

// ConversionItemView.swift - Individual File Row
struct ConversionItemView: View {
    @ObservedObject var item: ConversionItem
    
    var body: some View {
        HStack {
            // File Icon
            Image(systemName: "waveform")
                .foregroundColor(.blue)
                .frame(width: 20)
            
            // File Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.inputURL.lastPathComponent)
                    .font(.system(.body, design: .monospaced))
                
                HStack {
                    Text(item.inputURL.deletingLastPathComponent().lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let fileSize = item.fileSize {
                        Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Status and Progress
            VStack(alignment: .trailing, spacing: 4) {
                StatusIndicatorView(status: item.status)
                
                if item.status == .converting {
                    ProgressView(value: item.progress)
                        .frame(width: 100)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

