//
//  HimnoDetailView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/1/25.
//

import SwiftUI
import AVFoundation

struct HimnoDetailView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var playbackState: AudioPlaybackState
    @EnvironmentObject var reviewManager: ReviewManager
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settings: SettingsManager

    let himno: Himnario

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Himno #\(himno.title)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    Text(himno.himnarioVersion)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(himno.himnarioVersion == "Nuevo" ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                                        )
                                        .foregroundColor(himno.himnarioVersion == "Nuevo" ? .blue : .orange)
                                    
                                    if favoritesManager.isFavorite(id: himno.id, himnarioVersion: himno.himnarioVersion) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "heart.fill")
                                                .foregroundColor(.red)
                                            Text("Favorito")
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: toggleFavorite) {
                                ZStack {
                                    Circle()
                                        .fill(favoritesManager.isFavorite(id: himno.id, himnarioVersion: himno.himnarioVersion) ? Color.red.opacity(0.1) : Color(.systemGray5))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: favoritesManager.isFavorite(id: himno.id, himnarioVersion: himno.himnarioVersion) ? "heart.fill" : "heart")
                                        .font(.title2)
                                        .foregroundColor(favoritesManager.isFavorite(id: himno.id, himnarioVersion: himno.himnarioVersion) ? .red : .gray)
                                }
                            }
                            .scaleEffect(favoritesManager.isFavorite(id: himno.id, himnarioVersion: himno.himnarioVersion) ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: favoritesManager.isFavorite(id: himno.id, himnarioVersion: himno.himnarioVersion))
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
                    )
                    .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Letra")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Tamaño: \(Int(settings.fontSize))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(himno.himno)
                            .font(.system(size: settings.fontSize))
                            .lineSpacing(8)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 16)
                    
                    AudioControlView(himno: himno)
                        .environmentObject(playbackState)
                        .environmentObject(favoritesManager)
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .navigationBar)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear { reviewManager.trackHymnoViewed() }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            playbackState.isPlaying = false
        }
    }
    
    private func toggleFavorite() {
        let wasFavorite = favoritesManager.isFavorite(id: himno.id, himnarioVersion: himno.himnarioVersion)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if wasFavorite {
                favoritesManager.removeFromFavorites(id: himno.id, himnarioVersion: himno.himnarioVersion)
            } else {
                favoritesManager.addToFavorites(himno: himno)
                reviewManager.trackFavoriteAdded()
            }
        }
    }
    
    func loadAudio() { playbackState.himnoTitle = himno.title; AudioBrain.instance.getTrack { DispatchQueue.main.async {} } }
    func setAudioRequirement() { AudioBrain.instance.audioRequirement(coritoFav: himno.himnarioVersion, indexC: (himno.id - 1), isVocal: playbackState.isVocal) }
}

#Preview {
    let favoritesManager = FavoritesManager()
    let playbackState = AudioPlaybackState()
    HimnoDetailView(
        himno: Himnario(id: 1,
                        title: "Santo, Santo, Santo",
                        himno: "Santo, Santo, Santo, Señor omnipotente. Siempre el labio mío loores te dará. Santo, Santo, Santo, ten piedad benigna, Dios en tres personas, bendita Trinidad.",
                        isFavorito: false,
                        himnarioVersion: "Nuevo")
    )
    .environmentObject(favoritesManager)
    .environmentObject(playbackState)
    .environmentObject(SettingsManager.shared)
}
