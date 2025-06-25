//
//  SettingsManager.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/20/25.
//

import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("FontSizes") var fontSize: Double = 30.0
    @AppStorage("isDarkMode") var isDarkMode = false
}
