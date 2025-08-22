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
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tema de Navegación")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("Selecciona el color de tu app")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Colors.shared.getCurrentAccentColor().opacity(0.15))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "paintbrush.fill")
                                .font(.title2)
                                .foregroundColor(Colors.shared.getCurrentAccentColor())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Theme selection grid
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Colors.shared.getCurrentAccentColor().opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "palette.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Colors.shared.getCurrentAccentColor())
                        }
                        
                        Text("Temas Disponibles")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(NavigationBarTheme.allCases) { theme in
                            NavigationThemeCard(
                                theme: theme,
                                isSelected: settings.selectedNavigationTheme == theme.rawValue
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    settings.selectedNavigationTheme = theme.rawValue
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Colors.shared.getCurrentAccentColor().opacity(0.1), radius: 10, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Colors.shared.getCurrentAccentColor().opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                
                Spacer(minLength: 100)
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }
}

struct NavigationThemeCard: View {
    let theme: NavigationBarTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Preview gradient
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.gradient)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? theme.accentColor : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: theme.accentColor.opacity(isSelected ? 0.3 : 0.1), radius: isSelected ? 8 : 4, x: 0, y: 4)
                
                // Theme name
                Text(theme.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? theme.accentColor : .primary)
                    .multilineTextAlignment(.center)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? theme.accentColor.opacity(0.05) : Color(.systemBackground))
                    .shadow(color: .black.opacity(isSelected ? 0.1 : 0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? theme.accentColor.opacity(0.3) : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        NavigationBarThemeView()
            .environmentObject(SettingsManager.shared)
    }
} 