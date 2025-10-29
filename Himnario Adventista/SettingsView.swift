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
    @StateObject private var supportPromptManager = SupportPromptManager.shared
    @State private var showSupportScreen = false
    @State private var showDebugAlert = false
    @State private var debugMessage = ""
    
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
                
                NavigationLink(destination: NavigationBarThemeView()) {
                    Text("Cambiar Color")
                }
            }
            
            Section(header: Text("Opinión y Comentarios")) {
                Button(action: {
                    reviewManager.showCustomReviewPrompt()
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
            }
            
            Section(header: Text("Apoyo")) {
                Button(action: {
                    showSupportScreen = true
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Apoyar la Aplicación")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.primary)
            }
            
            
            
        }
        .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .padding(.top, 5)
        .sheet(isPresented: $showSupportScreen) {
            NavigationView {
                SupportScreen(isPresented: $showSupportScreen)
            }
        }
        .alert("Debug", isPresented: $showDebugAlert) {
            Button("OK") { }
        } message: {
            Text(debugMessage)
        }
        
    }
    
    private func openAppStore() {
        // Replace YOUR_APP_ID with your actual App Store ID
        if let writeReviewURL = URL(string: "https://apps.apple.com/app/id1525895857?action=write-review") {
            UIApplication.shared.open(writeReviewURL)
        } else {
            // Fallback to native review prompt if URL fails
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                AppStore.requestReview(in: windowScene)
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
}
