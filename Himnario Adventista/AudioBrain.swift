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
    
    //let playlistService = PlaylistService()
    let hostService = AudiusHostService()
    
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
    func getTrack(by trackId: String, title: String = "", completion: @escaping () -> Void) {
        isLoading = true
        
        self.trackId = trackId
        
        hostService.fetchAudiusHost { [weak self] resolvedHost in
            guard let self = self else { return }
            let host = resolvedHost ?? "https://audius-discovery-3.altego.net"
            let trackURLString = "\(host)/v1/tracks/\(trackId)?app_name=CoritosAdventistas"
            
            guard let encodedURL = trackURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encodedURL) else {
                debugPrint("Invalid track URL")
                self.cleanupAndComplete(completion: completion)
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard error == nil,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let trackData = json["data"] as? [String: Any],
                      let duration = trackData["duration"] as? Int else {
                    debugPrint("Failed to fetch track metadata")
                    self.cleanupAndComplete(completion: completion)
                    return
                }
                
                self.trackDuration = duration
                self.trackTime = self.formatTrackTime(seconds: duration)
                
                let streamURLString = "\(host)/v1/tracks/\(trackId)/stream?app_name=CoritosAdventistas"
                guard let streamURL = URL(string: streamURLString) else {
                    debugPrint("Invalid stream URL")
                    self.cleanupAndComplete(completion: completion)
                    return
                }
                
                AudioPlayerManager.shared.loadTrack(from: streamURL, duration: duration, title: title)
                self.cleanupAndComplete(completion: completion)
            }.resume()
        }
//        playlistService.findPlaylistURL(coritoFavorito: coritoFavorito,
//                                        isVoice: isVoice,
//                                        indexCorito: indexCorito) { [weak self] playlistURL in
//            guard let self = self else { return }
//            guard let finalURL = playlistURL else {
//                debugPrint("Could not get a valid playlist URL.")
//                DispatchQueue.main.async { completion() }
//                return
//            }
//            
//            NetworkService.shared.setURL(url: finalURL)
//            
//            NetworkService.shared.getHimnos { dataAPI in
//                
//                var dataIndex = 0
//                
//                switch self.indexCorito {
//                    case 0..<200:
//                        dataIndex = self.indexCorito
//                    case 200..<400:
//                        dataIndex = self.indexCorito - 200
//                    case 400..<600:
//                        dataIndex = self.indexCorito - 400
//                    default:
//                        dataIndex = self.indexCorito - 600
//                }
//                
//                guard dataIndex < dataAPI.data.count else {
//                    debugPrint("Index out of range in dataAPI.")
//                    DispatchQueue.main.async { completion() }
//                    self.isLoading = false
//                    return
//                }
//                
//                let himnoData = dataAPI.data[dataIndex]
//                self.trackId = himnoData.id
//                self.trackDuration = himnoData.duration
//                self.trackTime = self.formatTrackTime(seconds: himnoData.duration)
//                
//                self.playlistService.hostService.fetchAudiusHost { resolvedHost in
//                    let host = resolvedHost ?? "https://audius-discovery-3.altego.net"
//                    let streamURLString = "\(host)/v1/tracks/\(self.trackId)/stream?app_name=CoritosAdventistas"
//                    
//                    guard let encodedStreamURLString = streamURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
//                          let streamURL = URL(string: encodedStreamURLString) else {
//                        debugPrint("Invalid streaming URL.")
//                        DispatchQueue.main.async { completion() }
//                        self.isLoading = false
//                        return
//                    }
//                    
//                    AudioPlayerManager.shared.loadTrack(from: streamURL, duration: self.trackDuration)
//                    DispatchQueue.main.async {
//                        completion()
//                    }
//                }
//            } onError: { errorMessage in
//                debugPrint("Error fetching himnos: \(errorMessage)")
//                DispatchQueue.main.async { completion() }
//            }
//        }
    }
    
    private func cleanupAndComplete(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.isLoading = false
            completion()
        }
    }
    
    private func formatTrackTime(seconds: Int) -> String {
        let minutes = seconds / 60 % 60
        let secs = seconds % 60
        return String(format: "%02i:%02i", minutes, secs)
    }
}
