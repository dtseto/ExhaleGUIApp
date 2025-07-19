//
//  StatusIndicatorView.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//
import SwiftUI
import Foundation

// StatusIndicatorView.swift - Status Display
struct StatusIndicatorView: View {
    let status: ConversionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            statusIcon
            Text(status.displayName)
                .font(.caption)
                .foregroundColor(status.color)
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .pending:
            Image(systemName: "clock")
                .foregroundColor(.orange)
        case .converting:
            ProgressView()
                .scaleEffect(0.5)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }
}

