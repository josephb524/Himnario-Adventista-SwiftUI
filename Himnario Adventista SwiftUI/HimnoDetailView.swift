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
    @Environment(\.presentationMode) var presentationMode

    let himno: Himnario

    // Persist font size using AppStorage.
    @AppStorage("FontSize") private var fontSize: Double = 30.0

    var body: some View {
        NavigationView {
            VStack {
                // Main text display.
                HStack {
                    Spacer()
                    Button(action: toggleFavorite) {
                        Image(systemName: favoritesManager.isFavorite(id: himno.id, himnarioVersion: himno.himnarioVersion)
                              ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.largeTitle)
                        .padding()
                    }
                }
                ScrollView {
                    Text(himno.himno)
                        .font(.system(size: fontSize))
                        .padding()
                }
                
                // Instead of inline audio controls, we embed the global AudioControlView.
                AudioControlView(himno: himno)
                    .environmentObject(playbackState)
                    .environmentObject(favoritesManager)
                
                
                Spacer()
            }
            .navigationBarItems(leading: backButton)
            .toolbarBackground(Colors.shared.navigationBarGradient, for: .navigationBar)
            .navigationTitle("#\(himno.title)")
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
//        .onAppear {
//            
//            setAudioRequirement()
//            
//            if AudioPlayerManager.shared.coritoRate == 0.0 {
//                playbackState.himnoTitle = himno.title
//            }
//        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            playbackState.isPlaying = false
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
        if favoritesManager.isFavorite(id: himno.id, himnarioVersion: himno.himnarioVersion) {
            favoritesManager.removeFromFavorites(id: himno.id, himnarioVersion: himno.himnarioVersion)
        } else {
            favoritesManager.addToFavorites(himno: himno)
        }
    }
    
    // MARK: - Audio Functions
    
    func loadAudio() {
        playbackState.himnoTitle = himno.title
        
        AudioBrain.instance.getTrack {
            DispatchQueue.main.async {
                print("Track loaded")
            }
        }
    }
    
    func setAudioRequirement() {
        AudioBrain.instance.audioRequirement(coritoFav: himno.himnarioVersion,
                                              indexC: (himno.id - 1),
                                              isVocal: playbackState.isVocal)
    }
}

#Preview {
    let favoritesManager = FavoritesManager()
    let playbackState = AudioPlaybackState()
    HimnoDetailView(
        himno: Himnario(id: 1,
                        title: "Sample Himno",
                        himno: "Sample lyrics for the himno.",
                        isFavorito: false,
                        himnarioVersion: "Nuevo")
    )
    .environmentObject(favoritesManager)
    .environmentObject(playbackState)
}
