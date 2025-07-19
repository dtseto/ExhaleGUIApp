//
//  ConversionListView.swift
//  ExhaleGUIApp
//
//  Created by User2 on 7/18/25.
//
import SwiftUI
import Foundation

// ConversionListView.swift - File List with Progress
struct ConversionListView: View {
    @ObservedObject var audioConverter: AudioConverter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Conversion Queue")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            List {
                ForEach(audioConverter.conversionItems) { item in
                    ConversionItemView(item: item)
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(PlainListStyle())
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func deleteItems(offsets: IndexSet) {
        audioConverter.removeItems(at: offsets)
    }
}
