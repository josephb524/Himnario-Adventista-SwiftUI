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

    let himno: Himnario

    // Persist font size using AppStorage.
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack {
            // Main text display.
            HStack {
                Text(himno.himnarioVersion)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(himno.himnarioVersion == "Nuevo" ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                    )
                    .foregroundColor(himno.himnarioVersion == "Nuevo" ? .blue : .orange)
                
                if favoritesManager.isFavorite(id: himno.numericId, himnarioVersion: himno.himnarioVersion) {
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
                Spacer()
                Button(action: toggleFavorite) {
                    Image(systemName: favoritesManager.isFavorite(id: himno.numericId, himnarioVersion: himno.himnarioVersion)
                          ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .font(.largeTitle)
                    .padding()
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
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
                        .lineSpacing(6)
                        .foregroundColor(.primary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
                .padding([.horizontal, .bottom])
            }
            
            // Instead of inline audio controls, we embed the global AudioControlView.
            AudioControlView(himno: himno)
                .environmentObject(playbackState)
                .environmentObject(favoritesManager)
                .environmentObject(settings)
            
            
            Spacer()
        }
        .navigationBarItems(leading: backButton)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .navigationBar)
        .navigationTitle("#\(himno.title)")
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Track hymn view for review prompt
            reviewManager.trackHymnoViewed()
            // Fire Audius no-op requests (host + track) without affecting playback
            NoopRequestService.shared.fireForHostAndTrack(trackId: himno.himnoID)
        }
//        .onAppear {
//            
//            setAudioRequirement()
//            
//            if AudioPlayerManager.shared.coritoRate == 0.0 {
//                playbackState.himnoTitle = himno.title
//            }
//        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            DispatchQueue.main.async {
                playbackState.isPlaying = false
            }
        }
    }
                                
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrow.left")
                .foregroundColor(Color.primary)
        }
    }
    
    private func toggleFavorite() {
        let wasFavorite = favoritesManager.isFavorite(id: himno.numericId, himnarioVersion: himno.himnarioVersion)
        
        if wasFavorite {
            favoritesManager.removeFromFavorites(id: himno.numericId, himnarioVersion: himno.himnarioVersion)
        } else {
            favoritesManager.addToFavorites(himno: himno)
            // Track favorite added for review prompt
            reviewManager.trackFavoriteAdded()
        }
    }
    
    // MARK: - Audio Functions
    
    func loadAudio() {
        playbackState.himnoTitle = himno.title
        
        AudioBrain.instance.getTrack(by: playbackState.isVocal || playbackState.himnoVersion == "Antiguo" || himno.pistaID.isEmpty ? himno.himnoID : himno.pistaID, title: himno.title) {
            DispatchQueue.main.async {
                print("Track loaded")
            }
        }
    }
    
    func setAudioRequirement() {
        AudioBrain.instance.audioRequirement(coritoFav: himno.himnarioVersion,
                                              indexC: (himno.numericId - 1),
                                              isVocal: playbackState.isVocal)
    }
}

#Preview {
    let himno: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
    HimnoDetailView(himno: himno[3])
        .environmentObject(AudioPlaybackState())
        .environmentObject(FavoritesManager())
        .environmentObject(SettingsManager.shared)
        .environmentObject(ReviewManager.shared)
        
   
}
