import SwiftUI

struct AddToPlaylistView: View {
    @StateObject private var playlistManager = PlaylistManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let targetPlaylist: Playlist
    
    @State private var selectedHimnario = "Seventh-day Adventist Hymnal 1985"
    @State private var searchText = ""
    @State private var selectedSongs: Set<String> = []
    
    private var adventistHymnal: [Himnario] {
        Bundle.main.decode("adventistHymnal.json")
    }
    
    private var filteredHimnos: [Himnario] {
        if searchText.isEmpty {
            return adventistHymnal
        } else {
            return adventistHymnal.filter { himno in
                himno.title.localizedCaseInsensitiveContains(searchText) ||
                "\(himno.numericId)".contains(searchText)
            }
        }
    }
    
    private var availableHimnos: [Himnario] {
        return filteredHimnos.filter { himno in
            !playlistManager.isInPlaylist(himno: himno, playlist: targetPlaylist)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search hymns...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom)
                
                // Songs list
                List(availableHimnos, id: \.himnoID) { himno in
                    AddSongRow(
                        himno: himno,
                        isSelected: selectedSongs.contains(himno.himnoID)
                    ) {
                        toggleSelection(for: himno)
                    }
                }
                .listStyle(.plain)
                
                // Selected count and add button
                if !selectedSongs.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack {
                            Text("\(selectedSongs.count) song\(selectedSongs.count == 1 ? "" : "s") selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Add") {
                                addSelectedSongs()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Colors.shared.getCurrentAccentColor())
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationTitle("Add to \(targetPlaylist.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add All") {
                        addAllVisibleSongs()
                    }
                    .disabled(availableHimnos.isEmpty)
                }
            }
        }
    }
    
    private func toggleSelection(for himno: Himnario) {
        if selectedSongs.contains(himno.himnoID) {
            selectedSongs.remove(himno.himnoID)
        } else {
            selectedSongs.insert(himno.himnoID)
        }
    }
    
    private func addSelectedSongs() {
        let hymnsToAdd = availableHimnos.filter { selectedSongs.contains($0.himnoID) }
        
        for himno in hymnsToAdd {
            playlistManager.addToPlaylist(playlist: targetPlaylist, himno: himno)
        }
        
        dismiss()
    }
    
    private func addAllVisibleSongs() {
        for himno in availableHimnos {
            playlistManager.addToPlaylist(playlist: targetPlaylist, himno: himno)
        }
        
        dismiss()
    }
}

struct AddSongRow: View {
    let himno: Himnario
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Colors.shared.getCurrentAccentColor() : Color.secondary, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Colors.shared.getCurrentAccentColor())
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Song info
                VStack(alignment: .leading, spacing: 2) {
                    Text(himno.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(himno.numericId). \(himno.himnarioVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddToPlaylistView(targetPlaylist: Playlist(name: "Mi Playlist"))
        .environmentObject(PlaylistManager.shared)
} 