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
