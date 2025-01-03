//
//  TCLogMateApp.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 31/12/2024.
//

import SwiftUI

@main

struct TCLogMateApp: App {

    @StateObject var preferences = AppPreferences()
    var body: some Scene {
        WindowGroup {
            MainWindow().environmentObject(preferences)
        }.commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MyGreatApp") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: """
                                Utility for navigating the syslog file of the Teamcenter system (Siemens Digital Industries Software).
                                
                                License: MIT
                                Author:  Alexey Sedoykin
                                Contact: www.linkedin.com/in/sedoykin
                                """,
                                attributes: [
                                    NSAttributedString.Key.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                                    NSAttributedString.Key.foregroundColor: NSColor.textColor
                                ]
                            )
                        ]
                    )
                }
            }
        }
    
            Settings {
                PreferencesView()
                    .environmentObject(preferences)
            }
        }
    }


