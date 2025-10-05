//
//  SettingsView.swift
//  Adventist Hymnal
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
            Section(header: Text("Appearance")) {
                Toggle(isOn: $settings.isDarkMode) {
                    Text("Dark Mode")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size: \(Int(settings.fontSize))")
                    Slider(value: $settings.fontSize, in: 20...40, step: 1)
                }
                .padding(.vertical, 5)
                
                NavigationLink(destination: NavigationBarThemeView()) {
                    Text("Change Color")
                }
            }
            
            Section(header: Text("Feedback")) {
                Button(action: {
                    reviewManager.showCustomReviewPrompt()
                }) {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)
                        Text("Rate App")
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
