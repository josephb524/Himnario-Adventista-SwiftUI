//
//  SettingsView.swift
//  Concordancia Biblica
//
//  Created by Jose Pimentel on 6/22/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                }
            }
            .navigationTitle("Configuraciones")
            .toolbarBackground(Colors.shared.navigationBarGradient, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .padding(.top, 5)
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
