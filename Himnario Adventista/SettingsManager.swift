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
    @AppStorage("selectedNavigationTheme") var selectedNavigationTheme: String = NavigationBarTheme.defaultTheme.rawValue
    
    // Review prompt state
    @Published var showReviewPrompt = false
    
    // Support prompt state
    @Published var showSupportPrompt = false
    
    private init() {}
}
