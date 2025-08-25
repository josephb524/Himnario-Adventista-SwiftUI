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
    
    // Default to expanded view
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Always visible compact header
            compactHeader
            
            // Expandable content
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.height > 40 { // swipe down to collapse
                        withAnimation(.easeInOut(duration: 0.25)) { isExpanded = false }
                    }
                }
        )
    }
    
    private var compactHeader: some View {
        HStack(spacing: 12) {
            // Play/Pause button appears only in compact mode to avoid duplication
            if !isExpanded {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        togglePlayPause()
                    }
                }) {
                    Group {
                        if AudioBrain.instance.isLoading {
                            LoadingIndicatorView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: (playbackState.isPlaying && progressTimer.progress > 0.0)
                                ? "pause.fill"
                                : "play.fill")
                                .font(.title2)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 32, height: 32)
                }
            }
            
            // Title and mini progress
            VStack(alignment: .leading, spacing: 4) {
                Text(playbackState.himnoTitle.isEmpty ? himno.title : playbackState.himnoTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .truncationMode(.tail)
                    .padding(.vertical, 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !isExpanded {
                    // Mini progress bar in compact mode
                    ProgressView(value: progressTimer.progress)
                        .frame(height: 2)
                        .opacity(0.7)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { // tap title area toggles
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            }
            
            Spacer()
            
            // Track time (compact)
            if !isExpanded {
                Text(AudioBrain.instance.trackTime.isEmpty ? "00:00" : AudioBrain.instance.trackTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Expand/Collapse arrow
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    .animation(.easeInOut(duration: 0.25), value: isExpanded)
            }
            .accessibilityLabel(isExpanded ? "Collapse player" : "Expand player")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
    }
    
    private var expandedContent: some View {
        VStack(spacing: 14) {
            // Divider
            Divider()
                .padding(.horizontal, 16)
            
            // Full progress section
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    Text(AudioBrain.instance.trackTime.isEmpty ? "00:00" : AudioBrain.instance.trackTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                
                ProgressView(value: progressTimer.progress)
                    .padding(.horizontal, 16)
            }
            
            // Full control buttons
            HStack(spacing: 80) {
                // Stop button
                Button(action: stopPlayback) {
                    VStack(spacing: 4) {
                        Image(systemName: "stop.circle")
                            .font(.title)
                        Text("Stop")
                            .font(.caption2)
                    }
                }
                .disabled(AudioBrain.instance.isLoading)
                
                // Main play/pause (larger in expanded mode)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        togglePlayPause()
                    }
                }) {
                    Group {
                        if AudioBrain.instance.isLoading {
                            LoadingIndicatorView()
                        } else {
                            Image(systemName: (playbackState.isPlaying && progressTimer.progress > 0.0)
                                ? "pause.fill"
                                : "play.fill")
                                .font(.system(size: 44))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                
                // Vocal/Instrumental toggle
                Button(action: toggleVocalInstrumental) {
                    VStack(spacing: 4) {
                        Image(systemName: playbackState.isVocal ? "pianokeys" : "music.mic")
                            .font(.title)
                        Text(playbackState.isVocal ? "Pista" : "Canto")
                            .font(.caption2)
                    }
                }
                .disabled(AudioBrain.instance.isLoading || himno.himnarioVersion == "Antiguo")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
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
        AudioBrain.instance.getTrack(by: playbackState.isVocal ? himno.himnoID : himno.pistaID) {
            DispatchQueue.main.async {
                playbackState.progress = 0
                AudioPlayerManager.shared.play()
                playbackState.isPlaying = true
            }
        }
    }
}

#Preview {
    let himno: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
    AudioControlView(himno: himno[0])
        .environmentObject(AudioPlaybackState())
        .environmentObject(FavoritesManager())
        .environmentObject(ProgressBarTimer.instance)
}


