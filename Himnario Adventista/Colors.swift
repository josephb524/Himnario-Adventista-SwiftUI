//
//  Colors.swift
//  Concordancia Biblica
//
//  Created by Jose Pimentel on 12/1/24.
//

import SwiftUI

enum NavigationBarTheme: String, CaseIterable, Identifiable {
    case defaultTheme = "default"
    case sunset = "sunset"
    case ocean = "ocean"
    case forest = "forest"
    case pastel = "pastel"
    case midnight = "midnight"
    case royal = "royal"
    case warmth = "warmth"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .defaultTheme:
            return "Predeterminado"
        case .sunset:
            return "Atardecer"
        case .ocean:
            return "Océano"
        case .forest:
            return "Bosque"
        case .royal:
            return "Real"
        case .warmth:
            return "Calidez"
        case .pastel:
            return "Pastel"
        case .midnight:
            return "Medianoche"
        }
    }
    
    // Primary accent color representative of the theme
    var accentColor: Color {
        switch self {
        case .defaultTheme:
            return Color.blue
        case .sunset:
            return Color(red: 0.98, green: 0.36, blue: 0.64) // rose
        case .ocean:
            return Color(red: 0.00, green: 0.78, blue: 1.00) // bright turquoise
        case .forest:
            return Color(red: 0.29, green: 0.67, blue: 0.20) // leaf green
        case .royal:
            return Color(red: 0.69, green: 0.17, blue: 0.94) // vivid purple
        case .warmth:
            return Color(red: 1.00, green: 0.65, blue: 0.20) // vivid orange
        case .pastel:
            return Color(red: 0.78, green: 0.68, blue: 0.96) // lavender
        case .midnight:
            return Color(red: 0.45, green: 0.50, blue: 0.85) // lighter periwinkle blue
        }
    }
    
    // Get navigation bar text color
    var navigationTextColor: Color {
        return Color.primary // All themes use primary color now
    }
    
    // Get appropriate accent color based on appearance mode
    func getAccentColor(for colorScheme: ColorScheme) -> Color {
        return self.accentColor // No special handling needed anymore
    }
    
    var gradient: LinearGradient {
        switch self {
        case .defaultTheme:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue,
                    Color.purple,
                    Color.cyan
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case .sunset:
            // Coral → Rosado → Durazno
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.00, green: 0.51, blue: 0.38), // coral
                    Color(red: 0.98, green: 0.36, blue: 0.64), // rose
                    Color(red: 1.00, green: 0.80, blue: 0.52)  // peach
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case .ocean:
            // Turquesa brillante → Azul medio → Azul profundo
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.00, green: 0.78, blue: 1.00), // bright turquoise
                    Color(red: 0.00, green: 0.58, blue: 0.84), // aqua blue
                    Color(red: 0.00, green: 0.32, blue: 0.64)  // deep ocean blue
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case .forest:
            // Verde claro → Verde hoja → Verde pino
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.67, green: 0.87, blue: 0.39), // light green
                    Color(red: 0.29, green: 0.67, blue: 0.20), // leaf green
                    Color(red: 0.14, green: 0.45, blue: 0.20)  // pine green
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case .royal:
            // Morado vivo → Índigo intenso → Violeta oscuro
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.69, green: 0.17, blue: 0.94), // vivid purple
                    Color(red: 0.35, green: 0.10, blue: 0.82), // deep indigo
                    Color(red: 0.14, green: 0.11, blue: 0.41)  // dark violet
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case .warmth:
            // Dorado → Naranja vivo → Rojo coral
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.00, green: 0.84, blue: 0.27), // gold
                    Color(red: 1.00, green: 0.65, blue: 0.20), // vivid orange
                    Color(red: 0.98, green: 0.27, blue: 0.33)  // coral red
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case .pastel:
            // Lavanda suave → Celeste → Menta
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.78, green: 0.68, blue: 0.96), // lavender
                    Color(red: 0.65, green: 0.85, blue: 1.00), // baby blue
                    Color(red: 0.72, green: 0.95, blue: 0.90)  // mint
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case .midnight:
            // Lighter midnight theme → Periwinkle → Soft lavender → Light blue
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.45, green: 0.50, blue: 0.85), // periwinkle blue
                    Color(red: 0.60, green: 0.55, blue: 0.90), // soft lavender
                    Color(red: 0.70, green: 0.80, blue: 0.95)  // light blue
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    var previewColors: [Color] {
        switch self {
        case .defaultTheme:
            return [Color.blue, Color.purple, Color.cyan]
        case .sunset:
            return [
                Color(red: 1.00, green: 0.51, blue: 0.38),
                Color(red: 0.98, green: 0.36, blue: 0.64),
                Color(red: 1.00, green: 0.80, blue: 0.52)
            ]
        case .ocean:
            return [
                Color(red: 0.00, green: 0.78, blue: 1.00),
                Color(red: 0.00, green: 0.58, blue: 0.84),
                Color(red: 0.00, green: 0.32, blue: 0.64)
            ]
        case .forest:
            return [
                Color(red: 0.67, green: 0.87, blue: 0.39),
                Color(red: 0.29, green: 0.67, blue: 0.20),
                Color(red: 0.14, green: 0.45, blue: 0.20)
            ]
        case .royal:
            return [
                Color(red: 0.69, green: 0.17, blue: 0.94),
                Color(red: 0.35, green: 0.10, blue: 0.82),
                Color(red: 0.14, green: 0.11, blue: 0.41)
            ]
        case .warmth:
            return [
                Color(red: 1.00, green: 0.84, blue: 0.27),
                Color(red: 1.00, green: 0.65, blue: 0.20),
                Color(red: 0.98, green: 0.27, blue: 0.33)
            ]
        case .pastel:
            return [
                Color(red: 0.78, green: 0.68, blue: 0.96),
                Color(red: 0.65, green: 0.85, blue: 1.00),
                Color(red: 0.72, green: 0.95, blue: 0.90)
            ]
        case .midnight:
            return [
                Color(red: 0.45, green: 0.50, blue: 0.85), // periwinkle blue
                Color(red: 0.60, green: 0.55, blue: 0.90), // soft lavender
                Color(red: 0.70, green: 0.80, blue: 0.95)  // light blue
            ]
        }
    }
}

struct Colors {
    static var shared = Colors()
    
    // Keep the original for backward compatibility
    let navigationBarGradient = NavigationBarTheme.defaultTheme.gradient
    
    // Method to get the current selected navigation bar gradient
    func getNavigationBarGradient() -> LinearGradient {
        let selectedTheme = NavigationBarTheme(rawValue: SettingsManager.shared.selectedNavigationTheme) ?? .defaultTheme
        return selectedTheme.gradient
    }
    
    // Method to get the accent color for the selected theme
    func getCurrentAccentColor() -> Color {
        let selectedTheme = NavigationBarTheme(rawValue: SettingsManager.shared.selectedNavigationTheme) ?? .defaultTheme
        return selectedTheme.accentColor
    }
    
    // Method to get accent color that adapts to current appearance mode
    func getCurrentAccentColor(for colorScheme: ColorScheme) -> Color {
        let selectedTheme = NavigationBarTheme(rawValue: SettingsManager.shared.selectedNavigationTheme) ?? .defaultTheme
        return selectedTheme.getAccentColor(for: colorScheme)
    }
    
    // Method to get navigation bar text color
    func getNavigationTextColor() -> Color {
        let selectedTheme = NavigationBarTheme(rawValue: SettingsManager.shared.selectedNavigationTheme) ?? .defaultTheme
        return selectedTheme.navigationTextColor
    }
}
