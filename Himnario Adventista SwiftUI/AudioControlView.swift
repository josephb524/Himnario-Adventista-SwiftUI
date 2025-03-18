//
//  AudioControlView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/11/25.
//  Updated for modern player apps on 3/25/25.
//

import SwiftUI
import AVFoundation

struct AudioControlView: View {
    @EnvironmentObject var playbackState: AudioPlaybackState
    @EnvironmentObject var favoritesManager: FavoritesManager
    let himno: Himnario
    
    var body: some View {
        VStack(spacing: 10) {
            // Title and track time.
            HStack {
                Text(playbackState.himnoTitle.isEmpty ? himno.title : playbackState.himnoTitle)
                    .font(.headline)
                Spacer()
                Text(playbackState.trackTime)
                    .font(.subheadline)
            }
            .padding(.horizontal)
            
            // Progress bar.
            ProgressView(value: playbackState.progress)
                .padding(.horizontal)
            
            // Control buttons.
            HStack {
                if AudioBrain.instance.isLoading == true {
                    LoadingIndicatorView()
                    
                } else {
                    Button(action: togglePlayPause) {
                        Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.largeTitle)
                }
                
                }
                Spacer()
                Button(action: stopPlayback) {
                    Image(systemName: "stop.circle")
                        .font(.title)
                }
                .disabled(AudioBrain.instance.isLoading ? true : false)
                Spacer()
                Button(action: toggleVocalInstrumental) {
                    Image(systemName: playbackState.isVocal ? "pianokeys" : "music.mic")
                        .font(.title)
                    Text(playbackState.isVocal ? "pista" : "canto")
                }
                
                Spacer()
    
                
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    private func togglePlayPause() {
        if AudioPlayerManager.shared.audioPlayer == nil {
            startNewSong()
        } else {
            AudioPlayerManager.shared.playPause()
            if let status = AudioPlayerManager.shared.audioPlayer?.timeControlStatus {
                playbackState.isPlaying = (status == .playing)
            }
        }
    }
    
    private func stopPlayback() {
        AudioPlayerManager.shared.stop()
        AudioPlayerManager.shared.audioPlayer = nil
        playbackState.progress = 0
        playbackState.isPlaying = false
    }
    
    private func toggleVocalInstrumental() {
        playbackState.isVocal.toggle()
        AudioBrain.instance.isVoice = playbackState.isVocal
        startNewSong()
    }
    
    
    
    
    private func startNewSong() {
        
        playbackState.himnoTitle = himno.title
        AudioBrain.instance.audioRequirement(coritoFav: himno.himnarioVersion,
                                             indexC: (himno.id - 1),
                                             isVocal: playbackState.isVocal)
        
        AudioPlayerManager.shared.stop()
        AudioBrain.instance.getTrack {
            DispatchQueue.main.async {
                playbackState.progress = 0
                AudioPlayerManager.shared.play()
                playbackState.isPlaying = true
            }
        }
    }
}

//struct AudioControlView_Previews: PreviewProvider {
//    let himnarioNuevo: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
//    static var previews: some View {
//        AudioControlView(himno: himnarioNuevo[0])
//            .environmentObject(AudioPlaybackState())
//    }
//}
