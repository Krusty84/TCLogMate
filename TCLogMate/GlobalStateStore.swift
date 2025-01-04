//
//  GlobalStateStore.swift
//  TCLogMate
//
//  Created by Sedoykin Alexey on 04/01/2025.
//

import SwiftUI

class GlobalStateStore: ObservableObject {
    @Published var isSysLogFileLoading: Bool = false
    @Published var isSysLogFileLoaded: Bool = false
    @Published var syslogFileName: String = ""
}
