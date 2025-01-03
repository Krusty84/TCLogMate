//
//  Preferences.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 03/01/2025.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var prefs: AppPreferences
    
    var body: some View {
        Form {
            Section(header: Text("Highlight Color")) {
                // Let the user pick the highlight (selected line) color
                ColorPicker("Selected Line Background", selection: $prefs.highlightColor)
            }
            
            Section(header: Text("Category Colors")) {
                // For each known category, let the user pick a color
                ForEach(LogCategory.allCases, id: \.self) { cat in
                    ColorPicker("\(cat.rawValue) Color",
                                selection: binding(for: cat))
                }
            }
        }
        .padding()
        .frame(minWidth: 350, minHeight: 300)
    }
    
    /// A small helper to bind each category's color in the dictionary
    private func binding(for cat: LogCategory) -> Binding<Color> {
        Binding<Color>(
            get: { prefs.categoryColors[cat, default: .primary] },
            set: { newColor in
                prefs.categoryColors[cat] = newColor
            }
        )
    }
}
