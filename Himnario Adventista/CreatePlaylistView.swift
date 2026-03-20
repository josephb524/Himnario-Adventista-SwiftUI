import SwiftUI

struct CreatePlaylistView: View {
    @StateObject private var playlistManager = PlaylistManager.shared
    @StateObject private var supportPromptManager = SupportPromptManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlistName = ""
    @State private var playlistDescription = ""
    @State private var appeared = false
    
    private var monogram: String {
        let name = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "♪" }
        return String(name.prefix(1)).uppercased()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 28) {
                // Artwork with live monogram
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
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
                    
                    // Radial overlay
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Colors.shared.getCurrentAccentColor().opacity(0.1),
                                    Color.clear
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 180, height: 180)
                    
                    Text(monogram)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(Colors.shared.getCurrentAccentColor())
                        .animation(.easeInOut(duration: 0.2), value: monogram)
                }
                .shadow(color: Colors.shared.getCurrentAccentColor().opacity(0.15), radius: 12, x: 0, y: 6)
                .scaleEffect(appeared ? 1.0 : 0.85)
                .opacity(appeared ? 1.0 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)
                
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
                                    .stroke(
                                        playlistName.isEmpty
                                            ? Color.clear
                                            : Colors.shared.getCurrentAccentColor().opacity(0.4),
                                        lineWidth: 1
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: playlistName.isEmpty)
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
                                    .stroke(
                                        playlistDescription.isEmpty
                                            ? Color.clear
                                            : Colors.shared.getCurrentAccentColor().opacity(0.4),
                                        lineWidth: 1
                                    )
                            )
                            .lineLimit(3...6)
                            .animation(.easeInOut(duration: 0.2), value: playlistDescription.isEmpty)
                    }
                }
                .padding(.horizontal, 20)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
                
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
            .onAppear { appeared = true }
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