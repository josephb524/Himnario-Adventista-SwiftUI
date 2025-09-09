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
                HStack(spacing: 20) {
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
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Colors.shared.getCurrentAccentColor())
                        .clipShape(Capsule())
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
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Colors.shared.getCurrentAccentColor())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Colors.shared.getCurrentAccentColor().opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPlaylist.items.isEmpty)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowSeparator(.hidden)
            
            // Songs section
            Section {
                if currentPlaylist.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No hay canciones")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(currentPlaylist.isSystemPlaylist ? 
                             "Esta playlist del sistema está vacía" : 
                             "Agrega himnos a tu playlist para comenzar a escuchar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if !currentPlaylist.isSystemPlaylist {
                            Button("Añadir Canciones") {
                                showingAddSongs = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Colors.shared.getCurrentAccentColor())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(Array(currentPlaylist.items.enumerated()), id: \.element.id) { index, item in
                        PlaylistSongRow(
                            song: item,
                            index: index,
                            isCurrentlyPlaying: playlistAudioState.currentSong?.id == item.id && playlistAudioState.isPlaying,
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
                    HStack {
                        Text("\(currentPlaylist.items.count) canciones")
                            .font(.subheadline)
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
                        Button("Añadir Canciones") {
                            showingAddSongs = true
                        }
                        
                        Button("Editar Playlist") {
                            showingEditPlaylist = true
                        }
                        
                        Divider()
                        
                        Button("Eliminar Playlist", role: .destructive) {
                            // TODO: Add confirmation dialog
                            playlistManager.deletePlaylist(playlist: currentPlaylist)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
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

struct PlaylistHeaderView: View {
    let playlist: Playlist
    
    private var playlistIcon: String {
        if playlist.isSystemPlaylist {
            switch playlist.name {
            case "Himnario Nuevo":
                return "book.fill"
            case "Himnario Antiguo":
                return "book.closed.fill"
            case "Favoritos":
                return "heart.fill"
            default:
                return "music.note.list"
            }
        } else {
            return "music.note.list"
        }
    }
    
    private var playlistColor: Color {
        if playlist.isSystemPlaylist {
            switch playlist.name {
            case "Himnario Nuevo":
                return .blue
            case "Himnario Antiguo":
                return .brown
            case "Favoritos":
                return .red
            default:
                return Colors.shared.getCurrentAccentColor()
            }
        } else {
            return Colors.shared.getCurrentAccentColor()
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Playlist artwork
            RoundedRectangle(cornerRadius: 16)
                .fill(playlistColor.opacity(0.2))
                .frame(width: 200, height: 200)
                .overlay(
                    Image(systemName: playlistIcon)
                        .font(.system(size: 50))
                        .foregroundColor(playlistColor)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // Playlist info
            VStack(spacing: 8) {
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
                
                Text("\(playlist.songCount) canciones")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
}

struct PlaylistSongRow: View {
    let song: PlaylistItem
    let index: Int
    let isCurrentlyPlaying: Bool
    let onPlay: () -> Void
    let onRemove: (() -> Void)?
    let isSystemPlaylist: Bool
    
    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                // Track number or playing indicator
                ZStack {
                    Text("\(index + 1)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(isCurrentlyPlaying ? 0 : 1)
                    
                    if isCurrentlyPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.subheadline)
                            .foregroundColor(Colors.shared.getCurrentAccentColor())
                    }
                }
                .frame(width: 20)
                
                // Song info
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isCurrentlyPlaying ? Colors.shared.getCurrentAccentColor() : .primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(song.himnarioVersion) • Hymn \(song.numericId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // More menu
                if !isSystemPlaylist {
                    Menu {
                        Button("Play Next", action: {})
                        Button("Add to Playlist", action: {})
                        Divider()
                        if let onRemove = onRemove {
                            Button("Remove from Playlist", role: .destructive, action: onRemove)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Artwork placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(Colors.shared.getCurrentAccentColor().opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 40))
                                .foregroundColor(Colors.shared.getCurrentAccentColor())
                            Text(playlistName.isEmpty ? "Playlist" : playlistName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 20) {
                    // Playlist name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Mi Playlist", text: $playlistName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.subheadline)
                    }
                    
                    // Playlist description input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descripción (Opcional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Describe tu playlist", text: $playlistDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.subheadline)
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