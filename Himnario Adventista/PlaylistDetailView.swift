import SwiftUI

struct PlaylistDetailView: View {
    @StateObject private var playlistManager = PlaylistManager.shared
    @StateObject private var playbackState = AudioPlaybackState()
    @StateObject private var favoritesManager = FavoritesManager()
    @EnvironmentObject var playlistAudioState: PlaylistAudioState
    
    let playlist: Playlist
    @State private var showingAddSongs = false
    @State private var showingEditPlaylist = false
    
    private var currentPlaylist: Playlist {
        if playlist.isSystemPlaylist {
            return playlistManager.systemPlaylists.first(where: { $0.id == playlist.id }) ?? playlist
        } else {
            return playlistManager.playlists.first(where: { $0.id == playlist.id }) ?? playlist
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
            // Header section
            Section {
                PlaylistHeaderView(playlist: currentPlaylist)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            
            // Controls section
            Section {
                HStack(spacing: 12) {
                    // Play button
                    Button(action: {
                        if !currentPlaylist.items.isEmpty {
                            playlistAudioState.playPlaylist(currentPlaylist, startingAt: 0, shuffled: false)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.subheadline)
                            Text("Reproducir")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Colors.shared.getCurrentAccentColor(),
                                    Colors.shared.getCurrentAccentColor().opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Colors.shared.getCurrentAccentColor().opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPlaylist.items.isEmpty)
                    
                    // Shuffle button
                    Button(action: {
                        if !currentPlaylist.items.isEmpty {
                            let randomIndex = Int.random(in: 0..<currentPlaylist.items.count)
                            playlistAudioState.playPlaylist(currentPlaylist, startingAt: randomIndex, shuffled: true)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "shuffle")
                                .font(.subheadline)
                            Text("Aleatorio")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Colors.shared.getCurrentAccentColor())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Colors.shared.getCurrentAccentColor().opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPlaylist.items.isEmpty)
                }
                .padding(.vertical, 4)
            }
            .listRowSeparator(.hidden)
            
            // Songs section
            Section {
                if currentPlaylist.items.isEmpty {
                    PlaylistEmptyState(
                        isSystemPlaylist: currentPlaylist.isSystemPlaylist,
                        onAddSongs: { showingAddSongs = true }
                    )
                } else {
                    ForEach(Array(currentPlaylist.items.enumerated()), id: \.element.id) { index, item in
                        PlaylistSongRow(
                            song: item,
                            index: index,
                            isCurrentlyPlaying: playlistAudioState.currentSong?.id == item.id && playlistAudioState.isPlaying,
                            accentColor: getPlaylistColor(),
                            onPlay: {
                                playlistAudioState.playPlaylist(currentPlaylist, startingAt: index, shuffled: nil)
                            },
                            onRemove: currentPlaylist.isSystemPlaylist ? nil : {
                                deleteSong(at: index)
                            },
                            isSystemPlaylist: currentPlaylist.isSystemPlaylist
                        )
                    }
                    .onDelete(perform: currentPlaylist.isSystemPlaylist ? nil : deleteSongs)
                    .onMove(perform: currentPlaylist.isSystemPlaylist ? nil : moveSongs)
                }
            } header: {
                if !currentPlaylist.items.isEmpty {
                    HStack(spacing: 6) {
                        Text("\(currentPlaylist.items.count) canciones")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text(formatDuration(currentPlaylist.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            }
            
            // Mini Playlist Audio Player
            MiniPlaylistAudioPlayer()
                .environmentObject(playlistAudioState)
        }
        .navigationTitle(currentPlaylist.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !currentPlaylist.isSystemPlaylist {
                    Menu {
                        Button {
                            showingAddSongs = true
                        } label: {
                            Label("Añadir Canciones", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showingEditPlaylist = true
                        } label: {
                            Label("Editar Playlist", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            playlistManager.deletePlaylist(playlist: currentPlaylist)
                        } label: {
                            Label("Eliminar Playlist", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                } else {
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $showingAddSongs) {
            if !currentPlaylist.isSystemPlaylist {
                AddToPlaylistView(targetPlaylist: currentPlaylist)
                    .environmentObject(playlistManager)
            }
        }
        .sheet(isPresented: $showingEditPlaylist) {
            if !currentPlaylist.isSystemPlaylist {
                EditPlaylistView(playlist: currentPlaylist)
                    .environmentObject(playlistManager)
            }
        }
    }
    
    private func getPlaylistColor() -> Color {
        if playlist.isSystemPlaylist {
            switch playlist.name {
            case "Himnario Nuevo": return .blue
            case "Himnario Antiguo": return .brown
            case "Favoritos": return .red
            default: return Colors.shared.getCurrentAccentColor()
            }
        }
        return Colors.shared.getCurrentAccentColor()
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "~\(hours) h \(minutes) min"
        } else {
            return "~\(minutes) min"
        }
    }
    
    private func isCurrentlyPlaying(item: PlaylistItem) -> Bool {
        return playbackState.numericId == item.numericId && 
               playbackState.himnoVersion == item.himnarioVersion &&
               playbackState.isPlaying
    }
    
    private func deleteSong(at index: Int) {
        let item = currentPlaylist.items[index]
        playlistManager.removeFromPlaylist(playlist: currentPlaylist, item: item)
    }
    
    private func deleteSongs(offsets: IndexSet) {
        for index in offsets {
            let item = currentPlaylist.items[index]
            playlistManager.removeFromPlaylist(playlist: currentPlaylist, item: item)
        }
    }
    
    private func moveSongs(from source: IndexSet, to destination: Int) {
        playlistManager.moveItem(in: currentPlaylist, from: source, to: destination)
    }
}

// MARK: - Playlist Header View
struct PlaylistHeaderView: View {
    let playlist: Playlist
    @State private var animateArtwork = false
    
    private var playlistIcon: String {
        if playlist.isSystemPlaylist {
            switch playlist.name {
            case "Himnario Nuevo": return "book.fill"
            case "Himnario Antiguo": return "book.closed.fill"
            case "Favoritos": return "heart.fill"
            default: return "music.note.list"
            }
        } else {
            return "music.note.list"
        }
    }
    
    private var playlistColor: Color {
        if playlist.isSystemPlaylist {
            switch playlist.name {
            case "Himnario Nuevo": return .blue
            case "Himnario Antiguo": return .brown
            case "Favoritos": return .red
            default: return Colors.shared.getCurrentAccentColor()
            }
        } else {
            return Colors.shared.getCurrentAccentColor()
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Playlist artwork with gradient
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                playlistColor.opacity(0.35),
                                playlistColor.opacity(0.15),
                                playlistColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Subtle pattern overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                playlistColor.opacity(0.15),
                                Color.clear
                            ]),
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: playlistIcon)
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [playlistColor, playlistColor.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: playlistColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .shadow(color: playlistColor.opacity(0.2), radius: 16, x: 0, y: 8)
            .scaleEffect(animateArtwork ? 1.0 : 0.9)
            .opacity(animateArtwork ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateArtwork)
            .onAppear { animateArtwork = true }
            
            // Playlist info
            VStack(spacing: 6) {
                Text(playlist.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if !playlist.description.isEmpty {
                    Text(playlist.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10))
                    Text("\(playlist.songCount) canciones")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Empty State
private struct PlaylistEmptyState: View {
    let isSystemPlaylist: Bool
    let onAddSongs: () -> Void
    @State private var bounce = false
    
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Colors.shared.getCurrentAccentColor().opacity(0.08))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Colors.shared.getCurrentAccentColor().opacity(0.7),
                                Colors.shared.getCurrentAccentColor().opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: bounce ? -3 : 3)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: bounce
                    )
            }
            .onAppear { bounce = true }
            
            VStack(spacing: 6) {
                Text("No hay canciones")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(isSystemPlaylist ? 
                     "Esta playlist del sistema está vacía" : 
                     "Agrega himnos a tu playlist para\ncomenzar a escuchar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !isSystemPlaylist {
                Button(action: onAddSongs) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Añadir Canciones")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [
                                Colors.shared.getCurrentAccentColor(),
                                Colors.shared.getCurrentAccentColor().opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Colors.shared.getCurrentAccentColor().opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Waveform Animation
struct WaveformView: View {
    let color: Color
    @State private var animating = false
    
    private let barCount = 3
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 2.5, height: animating ? CGFloat.random(in: 6...14) : 4)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .frame(width: 14, height: 14)
        .onAppear { animating = true }
    }
}

// MARK: - Song Row
struct PlaylistSongRow: View {
    let song: PlaylistItem
    let index: Int
    let isCurrentlyPlaying: Bool
    var accentColor: Color = Colors.shared.getCurrentAccentColor()
    let onPlay: () -> Void
    let onRemove: (() -> Void)?
    let isSystemPlaylist: Bool
    
    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                // Mini thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    (isCurrentlyPlaying ? accentColor : Color.secondary).opacity(0.2),
                                    (isCurrentlyPlaying ? accentColor : Color.secondary).opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    if isCurrentlyPlaying {
                        WaveformView(color: accentColor)
                    } else {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Song info
                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isCurrentlyPlaying ? accentColor : .primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text("\(song.himnarioVersion) • Himno \(song.numericId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // More menu
                if !isSystemPlaylist {
                    Menu {
                        if let onRemove = onRemove {
                            Button(role: .destructive, action: onRemove) {
                                Label("Quitar de la Playlist", systemImage: "minus.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Playlist View
struct EditPlaylistView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    @Environment(\.dismiss) private var dismiss
    
    let playlist: Playlist
    @State private var playlistName: String
    @State private var playlistDescription: String
    
    init(playlist: Playlist) {
        self.playlist = playlist
        self._playlistName = State(initialValue: playlist.name)
        self._playlistDescription = State(initialValue: playlist.description)
    }
    
    private var monogram: String {
        let name = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "♪" }
        return String(name.prefix(1)).uppercased()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Artwork with live monogram
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Colors.shared.getCurrentAccentColor().opacity(0.3),
                                    Colors.shared.getCurrentAccentColor().opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 180, height: 180)
                    
                    Text(monogram)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(Colors.shared.getCurrentAccentColor())
                        .animation(.easeInOut(duration: 0.2), value: monogram)
                }
                .shadow(color: Colors.shared.getCurrentAccentColor().opacity(0.15), radius: 12, x: 0, y: 6)
                
                VStack(spacing: 20) {
                    // Playlist name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        TextField("Mi Playlist", text: $playlistName)
                            .font(.body)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Colors.shared.getCurrentAccentColor().opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Playlist description input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descripción (Opcional)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        TextField("Describe tu playlist", text: $playlistDescription, axis: .vertical)
                            .font(.body)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Colors.shared.getCurrentAccentColor().opacity(0.3), lineWidth: 1)
                            )
                            .lineLimit(3...6)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Editar Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveChanges()
                    }
                    .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedPlaylist = playlist
        updatedPlaylist.name = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedPlaylist.description = playlistDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        playlistManager.updatePlaylist(updatedPlaylist)
        dismiss()
    }
}

#Preview {
    PlaylistDetailView(playlist: Playlist(name: "Mi Playlist", description: "Una playlist de ejemplo"))
        .environmentObject(PlaylistManager.shared)
        .environmentObject(AudioPlaybackState())
        .environmentObject(FavoritesManager())
} 