class AudioPlaybackState: ObservableObject {
    @Published var trackTime: String = "00:00"
    @Published var progress: Float = 0.0
    @Published var isPlaying: Bool = false
    @Published var isVocal: Bool = true
}