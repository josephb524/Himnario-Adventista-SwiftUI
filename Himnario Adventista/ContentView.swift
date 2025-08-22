//
//  ContentView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 2/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var playbackState = AudioPlaybackState()
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var reviewManager = ReviewManager.shared
    
    let himnarioNuevo: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
    let himnarioViejo: [Himnario] = Bundle.main.decode("himnarioViejo.json")
    
    @State private var selectedHimnario: String = "Himnario Nuevo"
    let himnarios = ["Himnario Nuevo", "Himnario Antiguo"]
    
    init() {
        setupTabBarAppearance()
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            TabView {
                NavigationView {
                    VStack(spacing: 0) {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Himnario")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("Adventista")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            Picker("Selecciona el Himnario", selection: $selectedHimnario) {
                                ForEach(himnarios, id: \.self) { item in
                                    Text(item == "Himnario Nuevo" ? "Nuevo" : "Antiguo")
                                        .tag(item)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 20)
                            .tint(Colors.shared.getCurrentAccentColor())
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: Colors.shared.getCurrentAccentColor().opacity(0.1), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(Colors.shared.getCurrentAccentColor().opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        
                        HimnarioView(himnos: selectedHimnario == "Himnario Nuevo" ? himnarioNuevo : himnarioViejo)
                            .id(selectedHimnario)
                    }
                    .navigationBarHidden(true)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Himnario", systemImage: "music.note")
                }
                .environmentObject(favoritesManager)
                .environmentObject(playbackState)

                FavoriteView()
                    .tabItem {
                        Label("Favoritos", systemImage: "heart.fill")
                    }
                    .environmentObject(favoritesManager)
                    .environmentObject(playbackState)

                NavigationView {
                    SettingsView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Configuración", systemImage: "gearshape.fill")
                }
            }
            .preferredColorScheme(settings.isDarkMode ? .dark : .light)
            .tint(Colors.shared.getCurrentAccentColor())
            .environmentObject(settings)
            .environmentObject(reviewManager)
            
            if settings.showReviewPrompt {
                ReviewPromptView(
                    isPresented: $settings.showReviewPrompt,
                    onReviewAction: {
                        reviewManager.userLeftReview()
                    },
                    onDismiss: {}
                )
                .zIndex(1000)
            }
        }
        .onAppear {
            reviewManager.trackAppLaunch()
            updateTabBarAppearance()
        }
        .onChange(of: settings.selectedNavigationTheme) { _ in
            updateTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func updateTabBarAppearance() {
        DispatchQueue.main.async {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            let accentUIColor = UIColor(Colors.shared.getCurrentAccentColor())
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: accentUIColor
            ]
            appearance.stackedLayoutAppearance.selected.iconColor = accentUIColor
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray
            ]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}
