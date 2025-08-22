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
    @ObservedObject var progressTimer = ProgressBarTimer.instance
    let himno: Himnario
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with now playing info
            VStack(spacing: 8) {
                HStack {
                    Text("Reproduciendo")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(playbackState.himnoTitle.isEmpty ? himno.title : playbackState.himnoTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text("Himno #\(himno.title)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(AudioBrain.instance.trackTime.isEmpty ? "00:00" : AudioBrain.instance.trackTime)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                }
            }
            
            // Progress section
            VStack(spacing: 12) {
                ProgressView(value: progressTimer.progress)
                    .tint(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .scaleEffect(y: 2)
                
                HStack {
                    Text("0:00")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(AudioBrain.instance.trackTime.isEmpty ? "0:00" : AudioBrain.instance.trackTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Control buttons
            HStack(spacing: 32) {
                // Track mode toggle
                Button(action: toggleVocalInstrumental) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(.tertiarySystemBackground))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: playbackState.isVocal ? "pianokeys" : "music.mic")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                        
                        Text(playbackState.isVocal ? "Pista" : "Canto")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(AudioBrain.instance.isLoading || himno.himnarioVersion == "Antiguo")
                .opacity((AudioBrain.instance.isLoading || himno.himnarioVersion == "Antiguo") ? 0.5 : 1.0)
                
                Spacer()
                
                // Play/Pause button
                if AudioBrain.instance.isLoading {
                    LoadingIndicatorView()
                        .frame(width: 64, height: 64)
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            togglePlayPause()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 64, height: 64)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: (playbackState.isPlaying && progressTimer.progress > 0.0) ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .offset(x: (playbackState.isPlaying && progressTimer.progress > 0.0) ? 0 : 2)
                        }
                    }
                    .scaleEffect((playbackState.isPlaying && progressTimer.progress > 0.0) ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: playbackState.isPlaying)
                }
                
                Spacer()
                
                // Stop button
                Button(action: stopPlayback) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(.tertiarySystemBackground))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "stop.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                        
                        Text("Parar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(AudioBrain.instance.isLoading)
                .opacity(AudioBrain.instance.isLoading ? 0.5 : 1.0)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
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
        if playbackState.isPlaying {
            startNewSong()
        }
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

#Preview {
    AudioControlView(himno: Himnario(id: 1, title: "Santo, Santo, Santo", himno: "Sample lyrics", isFavorito: false, himnarioVersion: "Nuevo"))
        .environmentObject(AudioPlaybackState())
        .environmentObject(FavoritesManager())
        .padding()
        .background(Color(.systemGroupedBackground))
}
