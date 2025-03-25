//
//  SettingsView.swift
//  Concordancia Biblica
//
//  Created by Jose Pimentel on 6/22/24.
//

import SwiftUI

struct SettingsView: View {
//    @AppStorage("isDarkMode") private var isDarkMode = false
//    @AppStorage("FontSize") private var fontSize: Double = 30.0
    @EnvironmentObject var settings: SettingsManager
    
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
        }
        .toolbarBackground(Colors.shared.navigationBarGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .padding(.top, 5)
        
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
