//
//  SysLogFileParser.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 02/01/2025.
//

import SwiftUI

func parseSyslog(_ content: String) -> [LogLine] {
    let lines = content.components(separatedBy: .newlines)
    var parsedLines = [LogLine]()

    for line in lines {
        // uppercase for case-insensitive matching
        let upperLine = line.uppercased()
        var matchedCategory: LogCategory? = nil
        
        for cat in LogCategory.allCases {
            // Build a pattern, e.g. ".*\bERROR\b\s*-\s*.*"
            let pattern = ".*\\b\(cat.rawValue)\\b\\s*-\\s*.*"
            
            // If we find a match anywhere in upperLine, that line is cat.
            if upperLine.range(of: pattern, options: .regularExpression) != nil {
                matchedCategory = cat
                break
            }
        }
        
        parsedLines.append(LogLine(text: line, category: matchedCategory))
    }
    return parsedLines
}

func extractTimestamp(_ lineText: String) -> Date? {
    // Example pattern for "YYYY/MM/DD-HH:MM:SS(.ddd) optional"
    // This won't catch every format but demonstrates a typical approach.
    let pattern = #"\b(\d{4})/(\d{2})/(\d{2})-(\d{2}):(\d{2}):(\d{2})(\.\d{3})?\b"#
    
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: lineText, range: NSRange(lineText.startIndex..., in: lineText)) else {
        return nil
    }

    // Extract matched substring, e.g. "2024/12/31-11:50:35.542"
    let matchRange = match.range(at: 0)
    guard let swiftRange = Range(matchRange, in: lineText) else {
        return nil
    }
    let timestampString = String(lineText[swiftRange])

    // Convert "2024/12/31-11:50:35.542" -> "2024-12-31 11:50:35.542" for easier parsing
    let normalized = timestampString
        .replacingOccurrences(of: "/", with: "-")    // "2024-12-31-11:50:35.542"
        .replacingOccurrences(of: "-", with: " ", range: timestampString.index(timestampString.startIndex, offsetBy: 10)..<timestampString.index(timestampString.startIndex, offsetBy: 11))
        // Explanation:
        //  "YYYY/MM/DD-HH:MM:SS" -> "YYYY-MM-DD HH:MM:SS"
        //  Just an example approach; might need refining.

    // Now we might have "2024-12-31 11:50:35.542"
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"  // or "yyyy-MM-dd HH:mm:ss" if no milliseconds
    formatter.timeZone = TimeZone(identifier: "UTC")  // or local/timezone from the log

    // If there's no .SSS, parse again:
    if let date = formatter.date(from: normalized) {
        return date
    } else {
        // Fallback to second-level precision
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: normalized)
    }
}

func buildSummary(from lines: [LogLine]) -> LogSummary {
    let total = lines.count

    // Count categories
    var catCounts: [LogCategory: Int] = [:]
    for cat in LogCategory.allCases {
        catCounts[cat] = 0
    }

    // Timestamps
    var earliest: Date? = nil
    var latest: Date? = nil

    // For each line, increment category count + parse timestamps
    for line in lines {
        // 1) Category count
        if let cat = line.category {
            catCounts[cat, default: 0] += 1
        }

        // 2) Parse timestamp
        if let date = extractTimestamp(line.text) {
            if earliest == nil || date < earliest! {
                earliest = date
            }
            if latest == nil || date > latest! {
                latest = date
            }
        }
    }

    return LogSummary(
        totalLines: total,
        categoryCounts: catCounts,
        earliestTimestamp: earliest,
        latestTimestamp: latest
    )
}
