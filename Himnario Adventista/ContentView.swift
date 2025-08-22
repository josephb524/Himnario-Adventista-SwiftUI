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
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            TabView {
                // Hymnal Tab
                NavigationView {
                    VStack(spacing: 0) {
                        // Custom header with picker
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
                            
                            // Modern segmented picker
                            Picker("Selecciona el Himnario", selection: $selectedHimnario) {
                                ForEach(himnarios, id: \.self) { item in
                                    Text(item == "Himnario Nuevo" ? "Nuevo" : "Antiguo")
                                        .tag(item)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
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

                // Favorites Tab
                FavoriteView()
                    .tabItem {
                        Label("Favoritos", systemImage: "heart.fill")
                    }
                    .environmentObject(favoritesManager)
                    .environmentObject(playbackState)

                // Settings Tab
                NavigationView {
                    SettingsView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Configuración", systemImage: "gearshape.fill")
                }
            }
            .preferredColorScheme(settings.isDarkMode ? .dark : .light)
            .environmentObject(settings)
            .environmentObject(reviewManager)
            
            // Review prompt overlay
            if settings.showReviewPrompt {
                ReviewPromptView(
                    isPresented: $settings.showReviewPrompt,
                    onReviewAction: {
                        reviewManager.userLeftReview()
                    },
                    onDismiss: {
                        // Just dismiss, no additional action needed
                    }
                )
                .zIndex(1000)
            }
        }
        .onAppear {
            reviewManager.trackAppLaunch()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Customize tab bar item appearance
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
}
