import Foundation

// MARK: - Data Models
struct Playlist: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var items: [PlaylistItem]
    let createdAt: Date
    var updatedAt: Date
    let isSystemPlaylist: Bool
    
    init(name: String, description: String = "", isSystemPlaylist: Bool = false) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.items = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isSystemPlaylist = isSystemPlaylist
    }
    
    var duration: TimeInterval {
        // Estimate 3 minutes per hymn as default
        return Double(items.count) * 180
    }
    
    var songCount: Int {
        return items.count
    }
}

struct PlaylistItem: Codable, Identifiable, Hashable {
    let id: UUID
    let himnoID: String
    let pistaID: String
    let title: String
    let numericId: Int
    let himnarioVersion: String
    let addedAt: Date
    
    init(from himno: Himnario) {
        self.id = UUID()
        self.himnoID = himno.himnoID
        self.pistaID = himno.pistaID
        self.title = himno.title
        self.numericId = himno.numericId
        self.himnarioVersion = himno.himnarioVersion
        self.addedAt = Date()
    }
    
    // Convert back to Himnario for playback
    func toHimnario() -> Himnario {
        return Himnario(
            numericId: numericId,
            title: title,
            himno: "", // We don't store the full text, just placeholder
            himnoID: himnoID,
            pistaID: pistaID,
            himnarioVersion: himnarioVersion
        )
    }
}

// MARK: - Playlist Manager
class PlaylistManager: ObservableObject {
    static let shared = PlaylistManager()
    
    @Published var playlists: [Playlist] = []
    @Published var systemPlaylists: [Playlist] = []
    
    private let playlistsKey = "user_playlists"
    private let adventistHymnal: [Himnario] = Bundle.main.decode("adventistHymnal.json")
    
    private init() {
        loadPlaylists()
        createSystemPlaylists()
        setupFavoritesObserver()
    }
    
    // MARK: - Persistence
    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decodedPlaylists = try? JSONDecoder().decode([Playlist].self, from: data) {
            DispatchQueue.main.async {
                self.playlists = decodedPlaylists
            }
        }
    }
    
    private func savePlaylists() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: playlistsKey)
        }
    }
    
    // MARK: - Playlist Operations
    func createPlaylist(name: String, description: String = "") {
        let newPlaylist = Playlist(name: name, description: description)
        playlists.append(newPlaylist)
        savePlaylists()
        
        // Defer publish to next runloop to avoid warning if called in view update
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
    
    func deletePlaylist(playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
    
    func updatePlaylist(_ playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            var updatedPlaylist = playlist
            updatedPlaylist.updatedAt = Date()
            playlists[index] = updatedPlaylist
            savePlaylists()
            DispatchQueue.main.async { self.objectWillChange.send() }
        }
    }
    
    // MARK: - Playlist Item Operations
    func addToPlaylist(playlist: Playlist, himno: Himnario) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        
        // Check if song is already in playlist
        let exists = playlists[index].items.contains { item in
            item.himnoID == himno.himnoID && item.himnarioVersion == himno.himnarioVersion
        }
        
        if !exists {
            let newItem = PlaylistItem(from: himno)
            playlists[index].items.append(newItem)
            playlists[index].updatedAt = Date()
            savePlaylists()
            DispatchQueue.main.async { self.objectWillChange.send() }
        }
    }
    
    func removeFromPlaylist(playlist: Playlist, item: PlaylistItem) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        
        playlists[index].items.removeAll { $0.id == item.id }
        playlists[index].updatedAt = Date()
        savePlaylists()
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
    
    func moveItem(in playlist: Playlist, from source: IndexSet, to destination: Int) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        
        playlists[index].items.move(fromOffsets: source, toOffset: destination)
        playlists[index].updatedAt = Date()
        savePlaylists()
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
    
    // MARK: - System Playlists
    private func createSystemPlaylists() {
        // Create Adventist Hymnal 1985 playlist
        var hymnalPlaylist = Playlist(name: "Seventh-day Adventist Hymnal 1985", description: "All hymns from the 1985 hymnal", isSystemPlaylist: true)
        hymnalPlaylist.items = adventistHymnal.map { PlaylistItem(from: $0) }
            .sorted { $0.numericId < $1.numericId }
        
        // Create Favorites playlist (initially empty, will be populated by observer)
        let favoritesPlaylist = Playlist(name: "Favorites", description: "Your favorite hymns", isSystemPlaylist: true)
        
        DispatchQueue.main.async {
            self.systemPlaylists = [hymnalPlaylist, favoritesPlaylist]
            self.updateFavoritesPlaylist()
        }
    }
    
    private func setupFavoritesObserver() {
        // Listen for changes in favorites
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("FavoritesChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateFavoritesPlaylist()
        }
    }
    
    private func updateFavoritesPlaylist() {
        guard let favoritesIndex = systemPlaylists.firstIndex(where: { $0.name == "Favorites" }) else { return }
        
        var favoritesPlaylist = systemPlaylists[favoritesIndex]
        
        // Load favorites from UserDefaults directly
        if let data = UserDefaults.standard.data(forKey: "favoriteHimnos"),
           let favoriteHimnos = try? JSONDecoder().decode([Himnario].self, from: data) {
            favoritesPlaylist.items = favoriteHimnos.map { PlaylistItem(from: $0) }
        } else {
            favoritesPlaylist.items = []
        }
        
        favoritesPlaylist.updatedAt = Date()
        DispatchQueue.main.async {
            self.systemPlaylists[favoritesIndex] = favoritesPlaylist
        }
    }
    
    func refreshSystemPlaylists() {
        updateFavoritesPlaylist()
    }
    
    // MARK: - Utility
    func isInPlaylist(himno: Himnario, playlist: Playlist) -> Bool {
        return playlist.items.contains { item in
            item.himnoID == himno.himnoID && item.himnarioVersion == himno.himnarioVersion
        }
    }
    
    func getPlaylistsContaining(himno: Himnario) -> [Playlist] {
        let allPlaylists = playlists + systemPlaylists
        return allPlaylists.filter { playlist in
            isInPlaylist(himno: himno, playlist: playlist)
        }
    }
    
    func canEditPlaylist(_ playlist: Playlist) -> Bool {
        return !playlist.isSystemPlaylist
    }
    
    func canDeletePlaylist(_ playlist: Playlist) -> Bool {
        return !playlist.isSystemPlaylist
    }
} 