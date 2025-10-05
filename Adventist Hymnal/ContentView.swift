//
//  ContentView.swift
//  Adventist Hymnal SwiftUI
//
//  Created by Jose Pimentel on 2/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var favoritesManager = FavoritesManager()
//    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var playbackState = AudioPlaybackState()
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var reviewManager = ReviewManager.shared
    // Persist font size (if needed globally)
//    @AppStorage("FontSize") private var fontSize: Double = 30.0
    
    let adventistHymnal: [Himnario] = Bundle.main.decode("adventistHymnal.json")
    
    init() {
        setupTabBarAppearance()
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea(.all)
            TabView {
                // First Tab: Hymnal List
                NavigationView {
                    HimnarioView(himnos: adventistHymnal)
                        .navigationTitle("SDA Hymnal")
                        .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .navigationBar)
                        .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .tabBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Hymnal", systemImage: "music.note.list")
                }
                .environmentObject(favoritesManager)
                .environmentObject(playbackState)

                // Second Tab: Favorites
                FavoriteView()
                    .navigationTitle("Favorites")
                    .tabItem {
                        Label("Favorites", systemImage: "star")
                    }
                    .environmentObject(favoritesManager)
                    .environmentObject(playbackState)

                // Third Tab: Playlists
//                PlaylistsView()
//                    .tabItem {
//                        Label("Playlists", systemImage: "text.badge.plus")
//                    }
//                    .environmentObject(favoritesManager)
//                    .environmentObject(playbackState)
//                    .environmentObject(settings)

                // Fourth Tab: Settings
                NavigationView {
                    SettingsView()
                        .navigationTitle("Settings")
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
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
            // Track app launch when ContentView appears
            reviewManager.trackAppLaunch()
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
