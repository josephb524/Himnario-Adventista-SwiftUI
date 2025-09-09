import SwiftUI
import AVFoundation
import Combine

// MARK: - Playlist Audio State
class PlaylistAudioState: ObservableObject, PlaybackCompletionDelegate {
    @Published var isPlaying = false
    @Published var currentSong: PlaylistItem?
    @Published var currentPlaylist: Playlist?
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .off
    @Published var volume: Float = 0.7 {
        didSet {
            AudioPlayerManager.shared.audioPlayer?.volume = volume
        }
    }
    
    private var isLoadingSong = false
    
    // Playback queue & index for shuffle-aware navigation
    private var playbackQueue: [PlaylistItem] = []
    private var currentQueueIndex: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set this instance as the playback completion delegate
        ProgressBarTimer.instance.playbackCompletionDelegate = self
        
        // Fallback: listen to AVPlayer end notifications and advance when in playlist context
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if AudioPlayerManager.shared.playbackContext == .playlist {
                    DispatchQueue.main.async { self.trackDidComplete() }
                }
            }
            .store(in: &cancellables)
    }
    
    enum RepeatMode: String, CaseIterable {
        case off = "Off"
        case one = "One"
        case all = "All"
        
        var systemImage: String {
            switch self {
            case .off: return "repeat"
            case .one: return "repeat.1"
            case .all: return "repeat"
            }
        }
    }
    
    func playPlaylist(_ playlist: Playlist, startingAt index: Int = 0, shuffled: Bool? = nil) {
        // Explicitly set shuffle state if provided
        let shouldShuffle: Bool
        if let shuffled = shuffled {
            shouldShuffle = shuffled
            isShuffled = shuffled
        } else {
            shouldShuffle = isShuffled
        }
        
        if shouldShuffle {
            playShuffled(playlist, startingAt: index)
        } else {
            playInOrder(playlist, startingAt: index)
        }
    }
    
    func playInOrder(_ playlist: Playlist, startingAt index: Int = 0) {
        // Ensure this instance is set as the delegate for playlist playback
        ProgressBarTimer.instance.playbackCompletionDelegate = self
        
        isShuffled = false
        self.currentPlaylist = playlist
        rebuildQueue(around: index)
        guard !playbackQueue.isEmpty else { return }
        currentQueueIndex = min(index, playbackQueue.count - 1)
        currentSong = playbackQueue[currentQueueIndex]
        // Reset loading flag to allow immediate playback when switching playlists/modes
        isLoadingSong = false
        DispatchQueue.main.async { self.playCurrentSong() }
    }
    
    func playShuffled(_ playlist: Playlist, startingAt index: Int? = nil) {
        // Ensure this instance is set as the delegate for playlist playback
        ProgressBarTimer.instance.playbackCompletionDelegate = self
        
        isShuffled = true
        self.currentPlaylist = playlist
        let startIndex = index ?? Int.random(in: 0..<(playlist.items.count))
        rebuildQueue(around: startIndex)
        guard !playbackQueue.isEmpty else { return }
        currentQueueIndex = 0 // we moved the chosen start item to the front inside rebuildQueue
        currentSong = playbackQueue[currentQueueIndex]
        // Reset loading flag to allow immediate playback when switching playlists/modes
        isLoadingSong = false
        DispatchQueue.main.async { self.playCurrentSong() }
    }
    
    private func playCurrentSong() {
        guard let song = currentSong, !isLoadingSong else { return }
        
        isLoadingSong = true
        isPlaying = false
        
        // Set playback context to playlist
        AudioPlayerManager.shared.setPlaybackContext(.playlist)
        
        // For now default to vocal track; fall back if unavailable
        let trackId = (song.himnarioVersion == "Antiguo" || song.pistaID.isEmpty) ? song.himnoID : song.himnoID
        AudioPlayerManager.shared.stop()
        
        // Add timeout to prevent getting stuck in loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isLoadingSong {
                self.isLoadingSong = false
                self.isPlaying = false
            }
        }
        
        AudioBrain.instance.getTrack(by: trackId, title: song.title) {
            DispatchQueue.main.async {
                self.isLoadingSong = false
                AudioPlayerManager.shared.play()
                self.isPlaying = true
            }
        }
    }
    
    func togglePlayPause() {
        guard !isLoadingSong else { return }
        AudioPlayerManager.shared.playPause()
        if let status = AudioPlayerManager.shared.getAudioPlayer()?.timeControlStatus {
            isPlaying = (status == .playing)
        }
    }
    
    func nextSong() {
        guard !playbackQueue.isEmpty, !isLoadingSong else { return }
        currentQueueIndex = (currentQueueIndex + 1) % playbackQueue.count
        currentSong = playbackQueue[currentQueueIndex]
        DispatchQueue.main.async { self.playCurrentSong() }
    }
    
    func previousSong() {
        guard !playbackQueue.isEmpty, !isLoadingSong else { return }
        currentQueueIndex = (currentQueueIndex - 1 + playbackQueue.count) % playbackQueue.count
        currentSong = playbackQueue[currentQueueIndex]
        DispatchQueue.main.async { self.playCurrentSong() }
    }
    
    func seek(to position: Double) {
        ProgressBarTimer.instance.seek(to: position)
    }
    
    private func rebuildQueue(around startIndex: Int) {
        guard let playlist = currentPlaylist, !playlist.items.isEmpty else {
            playbackQueue = []
            currentQueueIndex = 0
            return
        }
        
        var base = playlist.items
        if isShuffled {
            base.shuffle()
            // Ensure the selected start item is at the first position in the queue
            if startIndex < playlist.items.count {
                let startItem = playlist.items[startIndex]
                if let idx = base.firstIndex(where: { $0.id == startItem.id }) {
                    base.swapAt(0, idx)
                }
            }
        } else {
            // Keep original order - no rearrangement needed for non-shuffled playback
            // The currentQueueIndex will be set properly in playPlaylist method
        }
        
        playbackQueue = base
    }
    
    // Toggle shuffle and rebuild the queue keeping current song at the front
    func toggleShuffle() {
        guard let playlist = currentPlaylist else { return }
        
        // Toggle the state
        isShuffled.toggle()
        
        // Find the current song's original index in the playlist
        let startIndex: Int
        if let current = currentSong, let idx = playlist.items.firstIndex(where: { $0.id == current.id }) {
            startIndex = idx
        } else {
            startIndex = 0
        }
        
        // Rebuild the queue based on new state using the proper methods
        // Rebuild the queue without restarting the current song
        rebuildQueueWithoutRestarting(playlist: playlist, currentSongIndex: startIndex)
    }
    
    private func rebuildQueueWithoutRestarting(playlist: Playlist, currentSongIndex: Int) {
        // Set the playlist and delegate
        ProgressBarTimer.instance.playbackCompletionDelegate = self
        self.currentPlaylist = playlist
        
        // Rebuild the queue
        rebuildQueue(around: currentSongIndex)
        guard !playbackQueue.isEmpty else { return }
        
        // Find the current song in the new queue and update the index
        if let currentSong = currentSong,
           let newIndex = playbackQueue.firstIndex(where: { $0.id == currentSong.id }) {
            currentQueueIndex = newIndex
        } else {
            // Fallback if current song not found
            currentQueueIndex = 0
            self.currentSong = playbackQueue[currentQueueIndex]
        }
    }
    
    // MARK: - PlaybackCompletionDelegate
    func trackDidComplete() {
        // Handle auto-advance based on repeat mode
        switch repeatMode {
        case .off:
            // Move to next song, stop if at end
            if currentQueueIndex < playbackQueue.count - 1 {
                nextSong()
            } else {
                // End of playlist reached
                isPlaying = false
                AudioPlayerManager.shared.stop()
            }
        case .one:
            // Repeat current song
            playCurrentSong()
        case .all:
            // Move to next song, loop back to beginning if at end
            nextSong()
        }
    }
}

// MARK: - Mini Playlist Audio Player
struct MiniPlaylistAudioPlayer: View {
    @EnvironmentObject var audioState: PlaylistAudioState
    @ObservedObject var progressTimer = ProgressBarTimer.instance
    @State private var showingNowPlaying = false
    
    var body: some View {
        if let currentSong = audioState.currentSong {
            VStack(spacing: 0) {
                // Progress bar (driven by global ProgressBarTimer)
                ProgressView(value: progressTimer.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Colors.shared.getCurrentAccentColor()))
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
                
                // Player controls
                HStack(spacing: 12) {
                    // Song artwork placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.secondary)
                        )
                    
                    // Song info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentSong.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(currentSong.himnarioVersion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Play/Pause button
                    Button(action: audioState.togglePlayPause) {
                        Image(systemName: audioState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(Colors.shared.getCurrentAccentColor())
                    }
                    
                    // Next button
                    Button(action: audioState.nextSong) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .contentShape(Rectangle())
                .onTapGesture {
                    showingNowPlaying = true
                }
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
            .sheet(isPresented: $showingNowPlaying) {
                PlaylistNowPlayingView()
                    .environmentObject(audioState)
            }
        }
    }
}

// MARK: - Full Screen Now Playing View
struct PlaylistNowPlayingView: View {
    @EnvironmentObject var audioState: PlaylistAudioState
    @ObservedObject var progressTimer = ProgressBarTimer.instance
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Large artwork
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 280, height: 280)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10)
                
                // Song info
                VStack(spacing: 8) {
                    Text(audioState.currentSong?.title ?? "Unknown Song")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(audioState.currentSong?.himnarioVersion ?? "Unknown Album")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Progress section
                VStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { progressTimer.progress },
                        set: { audioState.seek(to: $0) }
                    ), in: 0...1)
                    .accentColor(Colors.shared.getCurrentAccentColor())
                    
                    HStack {
                        Text(progressTimer.formattedCurrentTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(progressTimer.formattedRemainingTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Main controls
                HStack(spacing: 40) {
                    Button(action: audioState.previousSong) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: audioState.togglePlayPause) {
                        Image(systemName: audioState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Colors.shared.getCurrentAccentColor())
                    }
                    
                    Button(action: audioState.nextSong) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                }
                
                // Additional controls
                HStack(spacing: 50) {
                    Button(action: { audioState.toggleShuffle() }) {
                        Image(systemName: "shuffle")
                            .font(.title3)
                            .foregroundColor(audioState.isShuffled ? Colors.shared.getCurrentAccentColor() : .secondary)
                    }
                    
                    Button(action: { audioState.repeatMode = PlaylistAudioState.RepeatMode.allCases[(PlaylistAudioState.RepeatMode.allCases.firstIndex(of: audioState.repeatMode) ?? 0 + 1) % PlaylistAudioState.RepeatMode.allCases.count] }) {
                        Image(systemName: audioState.repeatMode.systemImage)
                            .font(.title3)
                            .foregroundColor(audioState.repeatMode != .off ? Colors.shared.getCurrentAccentColor() : .secondary)
                    }
                }
                
                // Volume control
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { audioState.volume },
                        set: { audioState.volume = $0 }
                    ), in: 0...1)
                    .accentColor(Colors.shared.getCurrentAccentColor())
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add to Playlist", action: {})
                        Button("Share", action: {})
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

 