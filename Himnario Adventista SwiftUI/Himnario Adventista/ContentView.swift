//
//  ContentView.swift
//  Himnario Adventista SwiftUI
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
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    // Persist font size (if needed globally)
//    @AppStorage("FontSize") private var fontSize: Double = 30.0
    
    let himnarioNuevo: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
    let himnarioViejo: [Himnario] = Bundle.main.decode("himnarioViejo.json")
    
    @State private var selectedHimnario: String = "Himnario Nuevo"
    let himnarios = ["Himnario Nuevo", "Himnario Antiguo"]
    
    @State private var selectedTab: Int = 0
    @State private var previousTab: Int = 0
    @State private var showPaywall: Bool = false
    
    init() {
        setupTabBarAppearance()
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea(.all)
            TabView(selection: $selectedTab) {
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
                            .id(selectedHimnario)
                    }
                    .navigationTitle("Himnario")
                    .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .navigationBar)
                    .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .tabBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Himnario", systemImage: "music.note.list")
                }
                .tag(0)
                .environmentObject(favoritesManager)
                .environmentObject(playbackState)

                // Second Tab: Favorites.

                FavoriteView()
                    .navigationTitle("Favoritos")

                    .tabItem {
                        Label("Favoritos", systemImage: "star")
                    }
                    .tag(1)
                    .environmentObject(favoritesManager)
                    .environmentObject(playbackState)

                // Third Tab: Playlists
                PlaylistsView()
                    .tabItem {
                        Label("Playlists", systemImage: "text.badge.plus")
                    }
                    .tag(2)
                    .environmentObject(favoritesManager)
                    .environmentObject(playbackState)
                    .environmentObject(settings)

                // Fourth Tab: Settings.
                NavigationView {
                    SettingsView()
                        .navigationTitle("Configuraciónes")
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Configuraciónes", systemImage: "gearshape")
                }
                .tag(3)
            }
            .preferredColorScheme(settings.isDarkMode ? .dark : .light)
            .environmentObject(settings)
            .environmentObject(reviewManager)
            .onChange(of: selectedTab) { newValue in
                // Gate the Playlists tab for non-subscribers
                if newValue == 2 && !subscriptionManager.isSubscribed {
                    showPaywall = true
                    selectedTab = previousTab
                } else {
                    previousTab = newValue
                }
            }
            .sheet(isPresented: $showPaywall) {
                NavigationView {
                    PaywallScreen(isPresented: $showPaywall)
                }
            }
            
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
