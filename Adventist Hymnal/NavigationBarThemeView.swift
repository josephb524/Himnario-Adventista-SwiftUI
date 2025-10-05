//
//  NavigationBarThemeView.swift
//  Adventist Hymnal SwiftUI
//
//  Created by Jose Pimentel on 3/20/25.
//

import SwiftUI

struct NavigationBarThemeView: View {
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Select Navigation Bar Theme")) {
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
        .navigationBarItems(leading: backButton)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Navigation Theme")
        .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrow.left")
                .foregroundColor(Color.primary)
        }
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
