//
//  SettingsView.swift
//  Concordancia Biblica
//
//  Created by Jose Pimentel on 6/22/24.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var reviewManager: ReviewManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Configuración")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("Personaliza tu experiencia")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            // Settings icon
                            ZStack {
                                Circle()
                                    .fill(Colors.shared.getCurrentAccentColor().opacity(0.15))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundColor(Colors.shared.getCurrentAccentColor())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Appearance Settings
                    SettingsCardView(title: "Apariencia", icon: "paintbrush.fill", iconColor: Colors.shared.getCurrentAccentColor()) {
                        VStack(spacing: 20) {
                            // Dark mode toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Modo Oscuro")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Cambiar entre tema claro y oscuro")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: $settings.isDarkMode)
                                    .toggleStyle(SwitchToggleStyle(tint: Colors.shared.getCurrentAccentColor()))
                            }
                            
                            Divider()
                            
                            // Font size slider
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Tamaño de Letra")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(Int(settings.fontSize))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Colors.shared.getCurrentAccentColor())
                                        .cornerRadius(8)
                                }
                                
                                HStack(spacing: 12) {
                                    Text("A")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Slider(value: $settings.fontSize, in: 20...40, step: 1)
                                        .tint(Colors.shared.getCurrentAccentColor())
                                    
                                    Text("A")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Ajusta el tamaño del texto en los himnos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            // Navigation theme
                            NavigationLink(destination: NavigationBarThemeView()) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Cambiar Color")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Personalizar barra de navegación")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    // Preview of current theme
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Colors.shared.getNavigationBarGradient())
                                        .frame(width: 40, height: 24)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(Colors.shared.getCurrentAccentColor().opacity(0.3), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Feedback Settings
                    SettingsCardView(title: "Opinión y Comentarios", icon: "star.fill", iconColor: .yellow) {
                        Button(action: {
                            reviewManager.showCustomReviewPrompt()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Calificar App")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Ayúdanos dejando una reseña")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func openAppStore() {
        if let writeReviewURL = URL(string: "https://apps.apple.com/app/id1525895857?action=write-review") {
            UIApplication.shared.open(writeReviewURL)
        } else {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                AppStore.requestReview(in: windowScene)
            }
        }
    }
}

struct SettingsCardView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
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
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(ReviewManager.shared)
}
