import SwiftUI
import AVFoundation

struct AudioControlView: View {
    @EnvironmentObject var playbackState: AudioPlaybackState

    var body: some View {
        // This view is always visible if audio is playing or paused.
        // In other parts of your UI, you can conditionally embed AudioControlView only if audio is active.
        VStack(spacing: 10) {
            // Title and track time.
            HStack {
                Text(playbackState.himnoTitle.isEmpty ? "Now Playing" : playbackState.himnoTitle)
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
                Button(action: togglePlayPause) {
                    Image(systemName: playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                Spacer()
                Button(action: stopPlayback) {
                    Image(systemName: "stop.circle")
                        .font(.title)
                }
                Spacer()
                Button(action: toggleVocalInstrumental) {
                    Image(systemName: playbackState.isVocal ? "music.mic" : "pianokeys")
                        .font(.title)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15)
                        .fill(Color.secondary.opacity(0.1)))
        .padding(.horizontal)
    }
    
    // MARK: - Button Actions
    
    private func togglePlayPause() {
        // If no audio is loaded, start the song.
        if AudioPlayerManager.shared.audioPlayer == nil {
            startNewSong()
        } else {
            AudioPlayerManager.shared.playPause()
            // Update our playback state immediately.
            if let status = AudioPlayerManager.shared.audioPlayer?.timeControlStatus {
                playbackState.isPlaying = (status == .playing)
            }
        }
    }
    
    private func stopPlayback() {
        AudioPlayerManager.shared.stop()
        playbackState.progress = 0
        playbackState.isPlaying = false
    }
    
    private func toggleVocalInstrumental() {
        playbackState.isVocal.toggle()
        startNewSong()
    }
    
    private func startNewSong() {
        // This method is called when the play button is tapped and there's no audio loaded,
        // or when toggling vocal/instrumental.
        // It ensures that playback starts immediately.
        AudioPlayerManager.shared.stop()
        // It is assumed that a parent view (or some other mechanism) has already set up the audio requirement via AudioBrain.
        // Here we simply fetch the track and play it.
        AudioBrain.instance.getTrack {
            DispatchQueue.main.async {
                playbackState.progress = 0
                AudioPlayerManager.shared.play()
                playbackState.isPlaying = true
            }
        }
    }
}

struct AudioControlView_Previews: PreviewProvider {
    static var previews: some View {
        AudioControlView()
            .environmentObject(AudioPlaybackState())
    }
}