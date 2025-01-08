//
//  SysLogFileStats.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 08/01/2025.
//

import SwiftUI

struct SysLogFileStatsView: View {
    let summary: LogSummary

    var body: some View {
         HStack() {
             Spacer()
             VStack(alignment: .leading) {
                 Text("Total Lines: \(summary.totalLines)")
                 if let earliest = summary.earliestTimestamp,
                    let latest = summary.latestTimestamp {
                     Text("Earliest: \(formatDate(earliest))")
                     Text("Latest:   \(formatDate(latest))")
                 } else {
                     Text("No timestamps found.")
                 }
             }.frame(maxWidth: .infinity, alignment: .leading)
             
             // Right column: Category counts
             VStack(alignment: .leading, spacing: 10) {
                 // Text("Category Counts").bold()
                 ForEach(LogCategory.allCases, id: \.self) { cat in
                     if let count = summary.categoryCounts[cat], count > 0 {
                         Text("\(cat.rawValue): \(count)")
                     }
                 }
             }
         }
     }

    // Helper to format a Date to string
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.timeZone = TimeZone.current
        return df.string(from: date)
    }
}

