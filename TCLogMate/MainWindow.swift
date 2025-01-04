//
//  ContentView.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 31/12/2024.
//

import SwiftUI

struct MainWindow: View {
    @State private var logLines: [LogLine] = []
    //@State private var fileName: String = ""
    @EnvironmentObject var gSs: GlobalStateStore
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
        gSs.syslogFileName.isEmpty ? "" : ": \(gSs.syslogFileName)"
    }
    
    private var loadStateText: String {
        if gSs.isSysLogFileLoading {
               return "Loading..."
        } else if !gSs.syslogFileName.isEmpty {
               return "Opened Syslog: \(gSs.syslogFileName)"
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
            gSs.isSysLogFileLoading = true
            //fileName = "..."
            self.logLines=[]
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let lines = parseSyslog(content)
                    // Switch back to main thread to update UI
                    DispatchQueue.main.async {
                        self.logLines = lines
                        gSs.isSysLogFileLoading = false
                        gSs.syslogFileName = url.lastPathComponent
                        gSs.isSysLogFileLoaded = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Error reading file: \(error)")
                        self.logLines = []
                        gSs.isSysLogFileLoading = false
                        gSs.isSysLogFileLoaded = false
                    }
                }
            }
        }
    }
}


//#Preview {
//    MainWindow()
//}
