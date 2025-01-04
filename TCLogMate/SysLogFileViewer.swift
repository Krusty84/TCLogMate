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
    // Search-related state
    @State private var searchText: String = ""
    @State private var searchResults: [UUID] = []
    @State private var currentSearchIndex: Int = 0
    // Currently selected line ID for search highlighting
    @State private var selectedSearchLineID: UUID? = nil
    //UI elemenents state
    @State private var isExpandedCategoryPanel = false
    @State private var isExpandedFindPanel = false
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
            DisclosureGroup(
                isExpanded: $isExpandedCategoryPanel,
                content: {
                    VStack(alignment: .leading) {
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
                    }
                    .padding(.leading, 10)
                },
                label: {
                    Text("Existing categories in the open syslog file")
                        .font(.title3)
                    //.padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    //.background(Color.orange.opacity(100))
                        .background(Color(nsColor: .windowBackgroundColor))
                    //.cornerRadius(8)
                        .onTapGesture {
                            withAnimation {
                                isExpandedCategoryPanel.toggle()
                            }
                        }
                }
            )
            Divider()
            DisclosureGroup(
                isExpanded: $isExpandedFindPanel,
                content: {
                    // Find Feature UI
                    HStack {
                        TextField("I am looking for...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.leading, 10)
                            .onChange(of: searchText) { newValue in
                                performSearch(query: newValue)
                            }
                        
                        Button("Prev") {
                            previousSearchResult()
                        }
                        .disabled(searchResults.isEmpty)
                        .padding(.horizontal, 5)
                        
                        Button("Next") {
                            nextSearchResult()
                        }
                        .disabled(searchResults.isEmpty)
                        .padding(.horizontal, 5)
                        
                        if !searchResults.isEmpty {
                            Text("\(currentSearchIndex + 1)/\(searchResults.count)")
                                .padding(.leading, 5)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                },
                label: {
                    Text("Search...")
                        .font(.title3)
                    //.padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    //.background(Color.orange.opacity(100))
                        .background(Color(nsColor: .windowBackgroundColor))
                    //.cornerRadius(8)
                        .onTapGesture {
                            withAnimation {
                                isExpandedFindPanel.toggle()
                            }
                        }
                }
            )
            
            
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
                                    //line.id == selectedLineID ? prefs.highlightColor : Color.clear
                                    (searchText.isEmpty ? line.id == selectedLineID : line.id == selectedSearchLineID)
                                    ? prefs.highlightColor
                                    : Color.clear
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
    
    private func performSearch(query: String) {
        if query.isEmpty {
            // Clear search results
            searchResults = []
            selectedSearchLineID = nil
            currentSearchIndex = 0
        } else {
            // Perform case-insensitive search
            searchResults = logLines
                .filter { $0.text.localizedCaseInsensitiveContains(query) }
                .map { $0.id }
            currentSearchIndex = 0
            if !searchResults.isEmpty {
                selectedSearchLineID = searchResults[0]
                scrollProxy?.scrollTo(searchResults[0], anchor: .top)
            } else {
                selectedSearchLineID = nil
            }
        }
    }
    
    private func nextSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
        let lineID = searchResults[currentSearchIndex]
        selectedSearchLineID = lineID
        scrollProxy?.scrollTo(lineID, anchor: .top)
    }
    
    private func previousSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
        let lineID = searchResults[currentSearchIndex]
        selectedSearchLineID = lineID
        scrollProxy?.scrollTo(lineID, anchor: .top)
    }
}



