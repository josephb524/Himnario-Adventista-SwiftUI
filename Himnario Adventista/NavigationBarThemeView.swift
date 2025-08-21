//
//  NavigationBarThemeView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/20/25.
//

import SwiftUI

struct NavigationBarThemeView: View {
    @EnvironmentObject var settings: SettingsManager
    
    var body: some View {
        Form {
            Section(header: Text("Selecciona el Tema de la Barra de Navegación")) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(NavigationBarTheme.allCases) { theme in
                        NavigationThemeCard(
                            theme: theme,
                            isSelected: settings.selectedNavigationTheme == theme.rawValue
                        ) {
                            settings.selectedNavigationTheme = theme.rawValue
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Tema de Navegación")
        .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct NavigationThemeCard: View {
    let theme: NavigationBarTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.gradient)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                    )
                
                Text(theme.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .opacity(isSelected ? 1 : 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationBarThemeView()
        .environmentObject(SettingsManager.shared)
} 