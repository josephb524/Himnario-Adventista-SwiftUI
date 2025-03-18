//
//  ContentView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 2/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var favoritesManager = FavoritesManager()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var playbackState = AudioPlaybackState()
    // Persist font size (if needed globally)
    @AppStorage("FontSize") private var fontSize: Double = 16.0
    
    let himnarioNuevo: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
    let himnarioViejo: [Himnario] = Bundle.main.decode("himnarioViejo.json")
    
    @State private var selectedHimnario: String = "Himnario Nuevo"
    let himnarios = ["Himnario Nuevo", "Himnario Antiguo"]
    
    init() {
        setupTabBarAppearance()
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea(.all)
            TabView {
                // First Tab: Himnario List with segmented Picker.
                NavigationView {
                    VStack {
                        Picker("Selecciona el Himnario", selection: $selectedHimnario) {
                            ForEach(himnarios, id: \.self) { item in
                                Text(item)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        HimnarioView(himnos: selectedHimnario == "Himnario Nuevo" ? himnarioNuevo : himnarioViejo)
                    }
                    .navigationTitle("Himnario")
                    .toolbarBackground(Colors.shared.navigationBarGradient, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .navigationBarBackButtonHidden()
                }
                .tabItem {
                    Label("Himnario", systemImage: "music.note.list")
                }
                .environmentObject(favoritesManager)
                .environmentObject(playbackState)
                
                // Second Tab: Favorites.
                
                FavoriteView()
                    .navigationTitle("Favoritos")
                
                    .tabItem {
                        Label("Favoritos", systemImage: "star")
                    }
                    .environmentObject(favoritesManager)
                    .environmentObject(playbackState)
                
                // Third Tab: Settings.
                NavigationView {
                    SettingsView()
                        .navigationTitle("Configuración")
                }
                .tabItem {
                    Label("Configuración", systemImage: "gearshape")
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
}
