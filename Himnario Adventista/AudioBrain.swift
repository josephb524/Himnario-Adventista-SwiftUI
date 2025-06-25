//
//  AudioBrain.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 8/22/21.
//  Updated for modern player apps on 3/25/25.
//

import Foundation
import AVFoundation

class AudioBrain {
    static let instance = AudioBrain()
    
    let playlistService = PlaylistService()
    
    var isLoading: Bool = false
    
    var trackId: String = ""
    var trackDuration: Int = 0
    var trackTime: String = ""
    
    var coritoFavorito: String = ""
    var isVoice: Bool = false
    var indexCorito: Int = 0  // Use this property consistently
    
    private init() {}
    
    /// Prepares the requirements for a certain corito.
    func audioRequirement(coritoFav: String, indexC: Int, isVocal: Bool) {
        coritoFavorito = coritoFav
        indexCorito = indexC
        self.isVoice = isVocal
    }
    
    /**
     Retrieves track metadata from the playlist URL, builds the streaming URL,
     and loads the track into the AudioPlayerManager.
     */
    func getTrack(completion: @escaping () -> Void) {
        isLoading = true
        playlistService.findPlaylistURL(coritoFavorito: coritoFavorito,
                                        isVoice: isVoice,
                                        indexCorito: indexCorito) { [weak self] playlistURL in
            guard let self = self else { return }
            guard let finalURL = playlistURL else {
                debugPrint("Could not get a valid playlist URL.")
                DispatchQueue.main.async { completion() }
                return
            }
            
            NetworkService.shared.setURL(url: finalURL)
            
            NetworkService.shared.getHimnos { dataAPI in
                
                var dataIndex = 0
                
                switch self.indexCorito {
                    case 0..<200:
                        dataIndex = self.indexCorito
                    case 200..<400:
                        dataIndex = self.indexCorito - 200
                    case 400..<600:
                        dataIndex = self.indexCorito - 400
                    default:
                        dataIndex = self.indexCorito - 600
                }
                
                guard dataIndex < dataAPI.data.count else {
                    debugPrint("Index out of range in dataAPI.")
                    DispatchQueue.main.async { completion() }
                    self.isLoading = false
                    return
                }
                
                let himnoData = dataAPI.data[dataIndex]
                self.trackId = himnoData.id
                self.trackDuration = himnoData.duration
                self.trackTime = self.formatTrackTime(seconds: himnoData.duration)
                
                self.playlistService.hostService.fetchAudiusHost { resolvedHost in
                    let host = resolvedHost ?? "https://audius-discovery-3.altego.net"
                    let streamURLString = "\(host)/v1/tracks/\(self.trackId)/stream?app_name=CoritosAdventistas"
                    
                    guard let encodedStreamURLString = streamURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                          let streamURL = URL(string: encodedStreamURLString) else {
                        debugPrint("Invalid streaming URL.")
                        DispatchQueue.main.async { completion() }
                        self.isLoading = false
                        return
                    }
                    
                    AudioPlayerManager.shared.loadTrack(from: streamURL, duration: self.trackDuration)
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            } onError: { errorMessage in
                debugPrint("Error fetching himnos: \(errorMessage)")
                DispatchQueue.main.async { completion() }
            }
        }
    }
    
    private func formatTrackTime(seconds: Int) -> String {
        let minutes = seconds / 60 % 60
        let secs = seconds % 60
        return String(format: "%02i:%02i", minutes, secs)
    }
}
