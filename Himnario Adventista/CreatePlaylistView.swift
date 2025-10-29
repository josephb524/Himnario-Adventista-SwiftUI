import SwiftUI

struct CreatePlaylistView: View {
    @StateObject private var playlistManager = PlaylistManager.shared
    @StateObject private var supportPromptManager = SupportPromptManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlistName = ""
    @State private var playlistDescription = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Artwork placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Nueva Playlist")
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
            .navigationTitle("Nueva Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Crear") {
                        createPlaylist()
                    }
                    .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func createPlaylist() {
        let trimmedName = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = playlistDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        playlistManager.createPlaylist(name: trimmedName, description: trimmedDescription)
        
        // Track playlist creation for support prompt
        supportPromptManager.trackPlaylistCreated()
        
        dismiss()
    }
}

#Preview {
    CreatePlaylistView()
        .environmentObject(PlaylistManager.shared)
} 