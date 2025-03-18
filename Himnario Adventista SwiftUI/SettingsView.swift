//
//  SettingsView.swift
//  Concordancia Biblica
//
//  Created by Jose Pimentel on 6/22/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("FontSize") private var fontSize: Double = 20.0
    
    var body: some View {
        
        Form {
            Section(header: Text("Apariencia")) {
                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size: \(Int(fontSize))")
                    Slider(value: $fontSize, in: 20...40, step: 1)
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
