import SwiftUI

struct PlaylistsView: View {
    @StateObject private var playlistManager = PlaylistManager.shared
    @StateObject private var playbackState = AudioPlaybackState()

    @StateObject private var settings = SettingsManager.shared
    @StateObject private var playlistAudioState = PlaylistAudioState()
    
    @State private var showingCreatePlaylist = false
    @State private var showingAddSongs = false
    @State private var selectedPlaylist: Playlist?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                Section {
                    Button(action: { showingCreatePlaylist = true }) {
                        PlaylistRow(icon: "plus.circle.fill", title: "Create new playlist")
                    }
                    .foregroundColor(.primary)
                }
                
                // System playlists section
                Section(header: Text("System playlists")) {
                    ForEach(playlistManager.systemPlaylists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist)
                            .environmentObject(playlistAudioState)
                        ) {
                            PlaylistRow(
                                icon: getSystemPlaylistIcon(for: playlist.name),
                                title: playlist.name,
                                subtitle: "\(playlist.songCount) songs",
                                iconColor: getSystemPlaylistColor(for: playlist.name)
                            )
                        }
                    }
                }

                Section(header: Text("Your playlists")) {
                    // User created playlists
                    ForEach(playlistManager.playlists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist)
                            .environmentObject(playlistAudioState)
                        ) {
                            PlaylistRow(
                                icon: "music.note.list",
                                title: playlist.name,
                                subtitle: "\(playlist.songCount) songs",
                                iconColor: Colors.shared.getCurrentAccentColor()
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                playlistManager.deletePlaylist(playlist: playlist)
                            }
                            
                            Button("Add songs") {
                                selectedPlaylist = playlist
                                showingAddSongs = true
                            }
                            .tint(Colors.shared.getCurrentAccentColor())
                        }
                    }
                }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Playlists")
                .onAppear {
                    DispatchQueue.main.async {
                        playlistManager.refreshSystemPlaylists()
                    }
                }
                .sheet(isPresented: $showingCreatePlaylist) {
                    CreatePlaylistView()
                }
                .sheet(isPresented: $showingAddSongs) {
                    if let playlist = selectedPlaylist {
                        AddToPlaylistView(targetPlaylist: playlist)
                    }
                }
                
                // Mini Playlist Audio Player
                MiniPlaylistAudioPlayer()
                    .environmentObject(playlistAudioState)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Helper functions for system playlist icons and colors
    private func getSystemPlaylistIcon(for name: String) -> String {
        switch name {
        case "Seventh-day Adventist Hymnal 1985":
            return "book.fill"
        case "Seventh-day Adventist Hymnal 1985":
            return "book.closed.fill"
        case "Favorites":
            return "heart.fill"
        default:
            return "music.note.list"
        }
    }
    
    private func getSystemPlaylistColor(for name: String) -> Color {
        switch name {
        case "Seventh-day Adventist Hymnal 1985":
            return .blue
        case "Seventh-day Adventist Hymnal 1985":
            return .brown
        case "Favorites":
            return .red
        default:
            return Colors.shared.getCurrentAccentColor()
        }
    }

}

private struct PlaylistRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color = .secondary

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.subheadline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PlaylistsView()
} 
