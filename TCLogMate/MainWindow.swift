//
//  ContentView.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 31/12/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct MainWindow: View {
    @State private var logLines: [LogLine] = []
    @State private var summary: LogSummary? = nil
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
            if gSs.isSysLogFileLoading {
                       ProgressView("Loading syslog file...")
                           .padding()
                           .progressViewStyle(CircularProgressViewStyle())
                       Text("Reading the dropped syslog. Please wait.")
                           .font(.footnote)
        
            } else {
                Divider()
                // Viewer is here
                SysLogFileViewer(logLines: logLines)
                Divider()
            }

        }
        .frame(minWidth: 800, minHeight: 600)
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            self.logLines.removeAll()
            gSs.isSysLogFileLoading = true
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (reading, error) in
                print("loadItem callback triggered. reading=\(reading) error=\(String(describing: error))")

                // 1) Try casting reading to Data
                if let data = reading as? Data {
                    // 2) Convert Data -> String
                    if let fileURLString = String(data: data, encoding: .utf8),
                       let url = URL(string: fileURLString) {
                        DispatchQueue.main.async {
                            print("Successfully decoded dropped URL = \(url)")
                            openFileDD(at: url)
                        }
                    } else {
                        print("Could not decode data as a UTF-8 file URL string")
                    }
                } else {
                    print("Could not cast reading to Data")
                }
            }
            return true
        }
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
    
    private func openFileDD(at url: URL) {
        self.logLines.removeAll()
        gSs.isSysLogFileLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let lines = parseSyslog(content)
                // Switch back to main thread to update UI
                DispatchQueue.main.async {
                    self.logLines = lines
                    self.summary = buildSummary(from: lines)
                    gSs.isSysLogFileLoading = false
                    gSs.syslogFileName = url.lastPathComponent
                    gSs.isSysLogFileLoaded = true
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error reading file: \(error)")
                    self.logLines.removeAll()
                    gSs.isSysLogFileLoading = false
                    gSs.isSysLogFileLoaded = false
                }
            }
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
            self.logLines.removeAll()
            gSs.isSysLogFileLoading = true
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let lines = parseSyslog(content)
                    // Switch back to main thread to update UI
                    DispatchQueue.main.async {
                        self.logLines = lines
                        self.summary = buildSummary(from: lines)
                        gSs.isSysLogFileLoading = false
                        gSs.syslogFileName = url.lastPathComponent
                        gSs.isSysLogFileLoaded = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Error reading file: \(error)")
                        self.logLines.removeAll()
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
