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
                    // Create new playlist card
                    Section {
                        Button(action: { showingCreatePlaylist = true }) {
                            CreatePlaylistCard()
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    
                    // System playlists section
                    Section {
                        ForEach(playlistManager.systemPlaylists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)
                                .environmentObject(playlistAudioState)
                            ) {
                                PlaylistRow(
                                    icon: getSystemPlaylistIcon(for: playlist.name),
                                    title: playlist.name,
                                    songCount: playlist.songCount,
                                    iconColor: getSystemPlaylistColor(for: playlist.name)
                                )
                            }
                        }
                    } header: {
                        PlaylistSectionHeader(title: "Listas del sistema", icon: "square.stack.fill")
                    }

                    Section {
                        if playlistManager.playlists.isEmpty {
                            // Empty state
                            EmptyPlaylistsCard()
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            // User created playlists
                            ForEach(playlistManager.playlists) { playlist in
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist)
                                    .environmentObject(playlistAudioState)
                                ) {
                                    PlaylistRow(
                                        icon: "music.note.list",
                                        title: playlist.name,
                                        songCount: playlist.songCount,
                                        iconColor: Colors.shared.getCurrentAccentColor()
                                    )
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        playlistManager.deletePlaylist(playlist: playlist)
                                    } label: {
                                        Label("Eliminar", systemImage: "trash.fill")
                                    }
                                    
                                    Button {
                                        selectedPlaylist = playlist
                                        showingAddSongs = true
                                    } label: {
                                        Label("Añadir", systemImage: "plus.circle.fill")
                                    }
                                    .tint(Colors.shared.getCurrentAccentColor())
                                }
                            }
                        }
                    } header: {
                        PlaylistSectionHeader(title: "Tus listas", icon: "person.fill")
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
        case "Himnario Nuevo":
            return "book.fill"
        case "Himnario Antiguo":
            return "book.closed.fill"
        case "Favoritos":
            return "heart.fill"
        default:
            return "music.note.list"
        }
    }
    
    private func getSystemPlaylistColor(for name: String) -> Color {
        switch name {
        case "Himnario Nuevo":
            return .blue
        case "Himnario Antiguo":
            return .brown
        case "Favoritos":
            return .red
        default:
            return Colors.shared.getCurrentAccentColor()
        }
    }

}

// MARK: - Create Playlist Card
private struct CreatePlaylistCard: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Colors.shared.getCurrentAccentColor().opacity(0.6),
                                Colors.shared.getCurrentAccentColor().opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Colors.shared.getCurrentAccentColor())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Crear nueva playlist")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Organiza tus himnos favoritos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Section Header
private struct PlaylistSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(Colors.shared.getCurrentAccentColor())
            
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Playlist Row
private struct PlaylistRow: View {
    let icon: String
    let title: String
    var songCount: Int = 0
    var iconColor: Color = .secondary

    var body: some View {
        HStack(spacing: 14) {
            // Gradient icon background
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                iconColor.opacity(0.25),
                                iconColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.body.weight(.medium))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .foregroundColor(.primary)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.system(size: 9))
                    Text("\(songCount) canciones")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State Card
private struct EmptyPlaylistsCard: View {
    @State private var iconBounce = false
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.note.list")
                .font(.system(size: 36))
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
                .offset(y: iconBounce ? -4 : 0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: iconBounce
                )
                .onAppear { iconBounce = true }
            
            VStack(spacing: 4) {
                Text("No tienes playlists")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Crea una playlist para organizar\ntus himnos favoritos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

#Preview {
    PlaylistsView()
} 
