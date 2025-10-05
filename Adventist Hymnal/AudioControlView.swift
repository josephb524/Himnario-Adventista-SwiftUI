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
    @EnvironmentObject var settings: SettingsManager
    @ObservedObject var progressTimer = ProgressBarTimer.instance
    let himno: Himnario
    
    // Default to expanded view
    @State private var isExpanded: Bool = true
    
    // Computed property to check if pista is available
    private var isPistaAvailable: Bool {
        return !himno.pistaID.isEmpty && himno.himnarioVersion != "Antiguo"
    }
    
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
            RoundedRectangle(cornerRadius: isExpanded ? 20 : 16, style: .continuous)
                .fill(Colors.shared.getCurrentAccentColor())
        )
        .overlay(alignment: .top) {
            // Top contrast band when expanded
            if isExpanded {
                RoundedBottomCorners(radius: 24)
                    .fill(Color.white.opacity(0.16))
                    .frame(height: 110)
                    .allowsHitTesting(false)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
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
            // Play/Pause button (compact)
            if !isExpanded {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        togglePlayPause()
                    }
                }) {
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(Color.white)
                        
                        // Progress ring
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progressTimer.progress))
                            .stroke(
                                Colors.shared.getCurrentAccentColor(),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: progressTimer.progress)
                        
                        // Play/pause icon
                        Group {
                            if AudioBrain.instance.isLoading {
                                LoadingIndicatorView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: (playbackState.isPlaying && progressTimer.progress > 0.0)
                                    ? "pause.fill"
                                    : "play.fill")
                                    .font(.headline)
                                    .foregroundColor(Colors.shared.getCurrentAccentColor())
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                }
            }
            
            // Title and subtitle - only show when NOT expanded
            if !isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    Text(playbackState.himnoTitle.isEmpty ? himno.title : playbackState.himnoTitle)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .allowsTightening(true)
                        .truncationMode(.tail)
                        .padding(.vertical, 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.white)
                    
                    Text("Himno No. \(playbackState.numericId == 0 ? himno.numericId : playbackState.numericId)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.85))
                }
                .contentShape(Rectangle())
                .onTapGesture { // tap title area toggles
                    withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
                }
                
                Spacer()
            } else {
                // When expanded, just show the chevron button centered
                Spacer()
            }
            
            // Expand/Collapse arrow
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .accessibilityLabel(isExpanded ? "Collapse player" : "Expand player")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
    }
    
    private var expandedContent: some View {
        VStack(spacing: 16) {
            
            // Single title/subtitle (keep once)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(playbackState.himnoTitle.isEmpty ? himno.title : playbackState.himnoTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("Himno No. \(playbackState.numericId == 0 ? himno.numericId : playbackState.numericId)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Controls row: centered play/pause, left stop, right Canto/Pista
            ZStack {
                // Centered play/pause button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        togglePlayPause()
                    }
                }) {
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                        
                        // Progress ring
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 4)
                            .frame(width: 72, height: 72)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progressTimer.progress))
                            .stroke(
                                Colors.shared.getCurrentAccentColor(),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 72, height: 72)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: progressTimer.progress)
                        
                        // Play/pause icon
                        Group {
                            if AudioBrain.instance.isLoading {
                                LoadingIndicatorView()
                            } else {
                                Image(systemName: (playbackState.isPlaying && progressTimer.progress > 0.0)
                                    ? "pause.fill"
                                    : "play.fill")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundColor(Colors.shared.getCurrentAccentColor())
                                    .transition(.scale.combined(with: .opacity))
                            }

                        }
                    }
                    .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 6)
                }
                
                // Leading stop and trailing Canto/Pista capsule on same row
                HStack {
                    // Stop button (left)
                    Button(action: stopPlayback) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                            Image(systemName: "stop.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Colors.shared.getCurrentAccentColor())
                        }
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.14), radius: 8, x: 0, y: 4)
                    }
                    
                    Spacer()
                    
                    // Canto/Pista capsule (right)
                    Button(action: toggleVocalInstrumental) {
                        HStack(spacing: 6) {
                            Text(playbackState.isVocal ? "Canto" : "Pista")
                            Image(systemName: playbackState.isVocal ? "music.mic" : "pianokeys")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isPistaAvailable ? Color.white : Color.white.opacity(0.5))
                        .foregroundColor(isPistaAvailable ? Colors.shared.getCurrentAccentColor() : Colors.shared.getCurrentAccentColor().opacity(0.4))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(isPistaAvailable ? 0.08 : 0.04), radius: 4, x: 0, y: 2)
                    }
                    .disabled(AudioBrain.instance.isLoading || !isPistaAvailable)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
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
        // Set playback context to individual for single hymn playback
        AudioPlayerManager.shared.setPlaybackContext(.individual)
        
        // Clear playlist delegate for individual playback
        ProgressBarTimer.instance.playbackCompletionDelegate = nil
        
        playbackState.himnoTitle = himno.title
        playbackState.numericId = himno.numericId
        playbackState.himnoVersion = himno.himnarioVersion
        AudioBrain.instance.audioRequirement(coritoFav: himno.himnarioVersion,
                                             indexC: (himno.numericId - 1),
                                             isVocal: playbackState.isVocal)
        
        AudioPlayerManager.shared.stop()
        AudioBrain.instance.getTrack(by: playbackState.isVocal || playbackState.himnoVersion == "Antiguo" || himno.pistaID.isEmpty ? himno.himnoID : himno.pistaID, title: himno.title) {
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
        .environmentObject(SettingsManager.shared)
}

struct RoundedBottomCorners: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


