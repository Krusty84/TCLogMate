//
//  SysLogFileModel.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 02/01/2025.
//

import SwiftUI
import UniformTypeIdentifiers

/// Possible categories we want to highlight.
enum LogCategory: String, CaseIterable {
    case info = "INFO"
    case note = "NOTE"
    case warning = "WARNING"
    case debug = "DEBUG"
    case error = "ERROR"
    // Add more if need...
}

/// Holds a single line of log text, along with its detected category.
struct LogLine: Identifiable {
    let id = UUID()
    let text: String
    let category: LogCategory?
}

struct LogSummary {
    let totalLines: Int
    let categoryCounts: [LogCategory: Int]
    let earliestTimestamp: Date?
    let latestTimestamp: Date?
}


class AppPreferences: ObservableObject {
    @Published var highlightColor: Color
    @Published var categoryColors: [LogCategory: Color]
    
    init() {
        // Default highlight color (background for the selected line)
        highlightColor = Color.yellow.opacity(0.3)
        
        // Default text color for each category
        categoryColors = [
            .info: .blue,
            .note: .purple,
            .warning: .orange,
            .debug: .gray,
            .error: .red
        ]
    }
}
