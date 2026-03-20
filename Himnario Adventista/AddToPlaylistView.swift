import SwiftUI

struct AddToPlaylistView: View {
    @StateObject private var playlistManager = PlaylistManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let targetPlaylist: Playlist
    
    @State private var selectedHimnario = "Himnario Nuevo"
    @State private var searchText = ""
    @State private var selectedSongs: Set<String> = []
    @FocusState private var isSearchFocused: Bool
    
    private let himnarios = ["Himnario Nuevo", "Himnario Antiguo"]
    
    private var himnarioNuevo: [Himnario] {
        Bundle.main.decode("himnarioNuevo.json")
    }
    
    private var himnarioViejo: [Himnario] {
        Bundle.main.decode("himnarioViejo.json")
    }
    
    private var currentHimnos: [Himnario] {
        selectedHimnario == "Himnario Nuevo" ? himnarioNuevo : himnarioViejo
    }
    
    private var filteredHimnos: [Himnario] {
        if searchText.isEmpty {
            return currentHimnos
        } else {
            return currentHimnos.filter { himno in
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
                // Himnario selector
                Picker("Selecciona el Himnario", selection: $selectedHimnario) {
                    ForEach(himnarios, id: \.self) { item in
                        Text(item)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline)
                        .foregroundColor(isSearchFocused ? Colors.shared.getCurrentAccentColor() : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
                    
                    TextField("Buscar himnos...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.subheadline)
                        .focused($isSearchFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSearchFocused
                                ? Colors.shared.getCurrentAccentColor().opacity(0.4)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
                .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
                
                // Songs list
                List(availableHimnos, id: \.himnoID) { himno in
                    AddSongRow(
                        himno: himno,
                        isSelected: selectedSongs.contains(himno.himnoID)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            toggleSelection(for: himno)
                        }
                    }
                }
                .listStyle(.plain)
                
                // Floating bottom bar
                if !selectedSongs.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 12) {
                            // Count badge
                            HStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(Colors.shared.getCurrentAccentColor())
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(selectedSongs.count)")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("seleccionada\(selectedSongs.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: addSelectedSongs) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.subheadline)
                                    Text("Añadir")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
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
                                .shadow(color: Colors.shared.getCurrentAccentColor().opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Añadir a \(targetPlaylist.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Añadir Todo") {
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

// MARK: - Add Song Row
struct AddSongRow: View {
    let himno: Himnario
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator with checkmark animation
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Colors.shared.getCurrentAccentColor() : Color.secondary.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Colors.shared.getCurrentAccentColor())
                            .frame(width: 24, height: 24)
                            .transition(.scale)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Mini artwork thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    (isSelected ? Colors.shared.getCurrentAccentColor() : Color.secondary).opacity(0.15),
                                    (isSelected ? Colors.shared.getCurrentAccentColor() : Color.secondary).opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(isSelected ? Colors.shared.getCurrentAccentColor() : .secondary)
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
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddToPlaylistView(targetPlaylist: Playlist(name: "Mi Playlist"))
        .environmentObject(PlaylistManager.shared)
} 