//
//  SettingsView.swift
//  Concordancia Biblica
//
//  Created by Jose Pimentel on 6/22/24.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
//    @AppStorage("isDarkMode") private var isDarkMode = false
//    @AppStorage("FontSize") private var fontSize: Double = 30.0
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var reviewManager: ReviewManager
    
    var body: some View {
        
        Form {
            Section(header: Text("Apariencia")) {
                Toggle(isOn: $settings.isDarkMode) {
                    Text("Modo Oscuro")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tamaño de Letra: \(Int(settings.fontSize))")
                    Slider(value: $settings.fontSize, in: 20...40, step: 1)
                }
                .padding(.vertical, 5)
            }
            
            Section(header: Text("Opinión y Comentarios")) {
                Button(action: {
                    settings.showReviewPrompt = true
                }) {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)
                        Text("Calificar App")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.primary)
                
                Button(action: {
                    openAppStore()
                }) {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .foregroundColor(.red)
                        Text("Escribir un Comentario")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.primary)
            }
            
            #if DEBUG
            Section(header: Text("Desarrollo (Solo Debug)")) {
                Button("Reiniciar Contador de Reseñas") {
                    reviewManager.resetReviewTracking()
                }
                .foregroundColor(.red)
                
                Button("Forzar Mostrar Reseña") {
                    reviewManager.forceShowReview()
                }
                .foregroundColor(.blue)
            }
            #endif
        }
        .toolbarBackground(Colors.shared.navigationBarGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .padding(.top, 5)
        
    }
    
    private func openAppStore() {
        // Replace YOUR_APP_ID with your actual App Store ID
        if let writeReviewURL = URL(string: "https://apps.apple.com/app/id1525895857?action=write-review") {
            UIApplication.shared.open(writeReviewURL)
        } else {
            // Fallback to native review prompt if URL fails
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
}

#Preview {
    let navigationBarGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.blue,
            Color.purple,
            Color.cyan
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    SettingsView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(ReviewManager.shared)
}
