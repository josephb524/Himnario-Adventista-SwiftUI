//
//  HimnarioNuevo.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 2/26/25.
//

import SwiftUI

struct HimnarioView: View {
    var himnos: [Himnario]
    @State private var searchText = ""
    @State private var isSearching = false
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var playbackState: AudioPlaybackState
    @EnvironmentObject var settings: SettingsManager
    let himnoSearch: HimnarioSearch = HimnarioSearch()
    @State private var himnoSearchResult: [Himnario] = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Search section
                VStack(spacing: 12) {
                    SearchBar(text: $searchText, onCommit: {
                        himnoSearchResult = himnoSearch.search(query: searchText, himnos: himnos)
                        isSearching = !searchText.isEmpty
                    }, onClear: {
                        searchText = ""
                        isSearching = false
                        himnoSearchResult = []
                    })
                    
                    if isSearching && !searchText.isEmpty {
                        HStack {
                            Text("Resultados para: \"\(searchText)\"")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(himnoSearchResult.count) himnos")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Colors.shared.getCurrentAccentColor().opacity(0.1))
                                .foregroundColor(Colors.shared.getCurrentAccentColor())
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Hymn list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if isSearching {
                            if himnoSearchResult.isEmpty {
                                // Empty search state
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("No se encontraron himnos")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Intenta con otras palabras clave")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 60)
                            } else {
                                ForEach(himnoSearchResult) { himno in
                                    NavigationLink(destination: HimnoDetailView(himno: himno)
                                        .environmentObject(favoritesManager)
                                        .environmentObject(playbackState)) {
                                        HymnRowView(himno: himno)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        } else {
                            ForEach(himnos) { himno in
                                NavigationLink(destination: HimnoDetailView(himno: himno)
                                    .environmentObject(favoritesManager)
                                    .environmentObject(playbackState)) {
                                    HymnRowView(himno: himno)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, playbackState.isPlaying ? 140 : 100) // Space for audio controls + tab bar
                }
                .background(Color(.systemGroupedBackground))
            }
            
            // Floating audio controls when playing - attached to bottom
            if playbackState.isPlaying && !playbackState.himnoTitle.isEmpty {
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: ProgressBarTimer.instance.progress)
                        .tint(Colors.shared.getCurrentAccentColor())
                        .scaleEffect(y: 2)
                    
                    // Control bar
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playbackState.himnoTitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text("Reproduciendo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            AudioPlayerManager.shared.playPause()
                            if let status = AudioPlayerManager.shared.audioPlayer?.timeControlStatus {
                                playbackState.isPlaying = (status == .playing)
                            }
                        }) {
                            Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Colors.shared.getCurrentAccentColor())
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            AudioPlayerManager.shared.stop()
                            AudioPlayerManager.shared.audioPlayer = nil
                            playbackState.progress = 0
                            playbackState.isPlaying = false
                        }) {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                }
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(.all, edges: .bottom)
                )
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: playbackState.isPlaying)
            }
        }
        .background(Color(.systemGroupedBackground))
        .id(settings.selectedNavigationTheme) // Force refresh when theme changes
    }
}

#Preview {
    let favoritesManager = FavoritesManager()
    let playbackState = AudioPlaybackState()
    let himnarioNuevo: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
    HimnarioView(himnos: himnarioNuevo)
        .environmentObject(favoritesManager)
        .environmentObject(playbackState)
        .environmentObject(SettingsManager.shared)
}
