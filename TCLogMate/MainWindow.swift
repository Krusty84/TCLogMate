//
//  ContentView.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 31/12/2024.
//

import SwiftUI

struct MainWindow: View {
    @State private var logLines: [LogLine] = []
    @State private var fileName: String = ""
    @State private var isLoading: Bool = false
    @EnvironmentObject var prefs: AppPreferences
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    openFile()
                }) {
                    Text(loadStateText)
                }.font(.title3)
                .padding(.top, 5)
            }
            Divider()
            
            // Viewer is here
            SysLogFileViewer(logLines: logLines)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    private var fileNameTitleSuffix: String {
        fileName.isEmpty ? "" : ": \(fileName)"
    }
    
    private var loadStateText: String {
           if isLoading {
               return "Loading..."
           } else if !fileName.isEmpty {
               return "Opened Syslog: \(fileName)"
           } else {
               return "Open Syslog"
           }
       }
    
    private func openFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a syslog file"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.plainText, .data]
        
        // This call is synchronous (blocking) on the main thread.
        // The user picks a file or cancels.
        if openPanel.runModal() == .OK, let url = openPanel.url {
            fileName = "..."
            isLoading = true
            self.logLines=[]
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let lines = parseSyslog(content)
                    // Switch back to main thread to update UI
                    DispatchQueue.main.async {
                        self.logLines = lines
                        self.isLoading = false
                        fileName = url.lastPathComponent
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Error reading file: \(error)")
                        self.logLines = []
                        self.isLoading = false
                    }
                }
            }
        }
    }
}


//#Preview {
//    MainWindow()
//}
