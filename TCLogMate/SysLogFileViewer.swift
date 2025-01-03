//
//  SysLogFileViewer.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 02/01/2025.
//

import SwiftUI

struct SysLogFileViewer: View {
    let logLines: [LogLine]
    @EnvironmentObject var prefs: AppPreferences
    // For programmatic scrolling
    @State private var scrollProxy: ScrollViewProxy?
    
    // For each category, which line IDs match?
    private var categoryLineIDs: [LogCategory: [UUID]] = [:]
    
    // Track the "currently selected" offset within each category
    @State private var currentOffsets: [LogCategory: Int] = [:]
    
    // Which line is highlighted right now?
    @State private var selectedLineID: UUID? = nil
    
    // Derived: which categories actually appear in the log
    private var appearingCategories: [LogCategory] {
        // Sort by rawValue so they appear in a consistent order
        categoryLineIDs.keys.sorted { $0.rawValue < $1.rawValue }
    }
    
    // Helper: color mapping for categories
    private func textColor(for category: LogCategory?) -> Color {
        switch category {
        case .info:     return .blue
        case .note:     return .purple
        case .warning:  return .orange
        case .debug:    return .gray
        case .error:    return .red
        default:        return .primary
        }
    }
    
    // Initialize dictionary of categories -> line IDs
    init(logLines: [LogLine]) {
        self.logLines = logLines
        var dict: [LogCategory: [UUID]] = [:]
        for cat in LogCategory.allCases {
            let ids = logLines
                .filter { $0.category == cat }
                .map { $0.id }
            if !ids.isEmpty {
                dict[cat] = ids
            }
        }
        self.categoryLineIDs = dict
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("===Existing categories in the open syslog file===")
                .font(.title3)
                .padding(.top, 5)
            // A horizontal row for each *appearing* category,
            // with a "prev" button, a label showing e.g. "ERROR (8/99)", and a "next" button.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(appearingCategories, id: \.self) { cat in
                        HStack {
                            Button("<") {
                                scrollToPreviousOccurrence(of: cat)
                            }
                            
                            // Show label: e.g. "ERROR (8/99)"
                            Text(categoryLabel(cat))
                                .foregroundColor(colorForCategory(cat))
                                .fontWeight(.semibold)
                            
                            Button(">") {
                                scrollToNextOccurrence(of: cat)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding()
            }
            
            Divider()
            
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading) {
                        ForEach(logLines) { line in
                            Text(line.text)
                            // Use the user-chosen text color for that category
                                .foregroundColor(colorForCategory(line.category))
                                .padding(4)
                            // If selected, show the user-chosen highlight color
                                .background(
                                    line.id == selectedLineID ? prefs.highlightColor : Color.clear
                                )
                                .cornerRadius(4)
                                .onTapGesture {
                                    // Example: tapping a line could select/highlight it
                                    selectedLineID = line.id
                                    withAnimation {
                                        proxy.scrollTo(line.id, anchor: .top)
                                    }
                                }
                                .id(line.id)
                        }
                    }
                    .padding()
                    .onAppear {
                        scrollProxy = proxy
                    }
                }
            }
        }
    }
        
    /// Go backward within the specified category, cycling if needed.
    private func scrollToPreviousOccurrence(of cat: LogCategory) {
        guard let ids = categoryLineIDs[cat], !ids.isEmpty else { return }
        let current = currentOffsets[cat] ?? 0
        // Move backward by 1, wrapping if negative
        let prev = (current - 1 + ids.count) % ids.count
        currentOffsets[cat] = prev
        
        let lineID = ids[prev]
        selectedLineID = lineID
        scrollProxy?.scrollTo(lineID, anchor: .top)
    }
    
    /// Go forward within the specified category, cycling if needed.
    private func scrollToNextOccurrence(of cat: LogCategory) {
        guard let ids = categoryLineIDs[cat], !ids.isEmpty else { return }
        let current = currentOffsets[cat] ?? -1
        // Move forward by 1, wrapping
        let next = (current + 1) % ids.count
        currentOffsets[cat] = next
        
        let lineID = ids[next]
        selectedLineID = lineID
        scrollProxy?.scrollTo(lineID, anchor: .top)
    }
    
    /// Shows e.g. "ERROR (8/99)" indicating we are on the 8th occurrence out of 99 total
    private func categoryLabel(_ cat: LogCategory) -> String {
        guard let ids = categoryLineIDs[cat], !ids.isEmpty else {
            return cat.rawValue // e.g. "ERROR"
        }
        let total = ids.count
        let offset = currentOffsets[cat] ?? 0
        // offset is 0-based, user-facing index is offset+1
        let currentDisplay = offset + 1
        return "\(cat.rawValue) (\(currentDisplay)/\(total))"
    }
    
    private func colorForCategory(_ category: LogCategory?) -> Color {
        guard let cat = category else {
            return .primary
        }
        return prefs.categoryColors[cat, default: .primary]
    }
}



