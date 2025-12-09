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
    
    @Published var trackTime: String = "00:00"
    @Published var isLoading: Bool = false
    
    private var currentTask: URLSessionDataTask?
    private var trackId: String = ""
    private var trackDuration: Int = 0
    
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
    /// Fetches the streaming URL for a given track ID.
    func fetchTrackURL(by trackId: String, completion: @escaping (URL?, Int?) -> Void) {
        // Cancel any existing request if it's for the same track? 
        // For now, we'll just let parallel requests happen since we might be prefetching.
        
        hostService.fetchAudiusHost { [weak self] resolvedHost in
            guard let _ = self else { return }
            let host = resolvedHost ?? "https://audius-discovery-3.altego.net"
            let trackURLString = "\(host)/v1/tracks/\(trackId)?app_name=CoritosAdventistas"
            
            guard let encodedURL = trackURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encodedURL) else {
                debugPrint("Invalid track URL")
                completion(nil, nil)
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                guard error == nil,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let trackData = json["data"] as? [String: Any],
                      let duration = trackData["duration"] as? Int else {
                    debugPrint("Failed to fetch track metadata")
                    completion(nil, nil)
                    return
                }
                
                let streamURLString = "\(host)/v1/tracks/\(trackId)/stream?app_name=CoritosAdventistas"
                guard let streamURL = URL(string: streamURLString) else {
                    debugPrint("Invalid stream URL")
                    completion(nil, nil)
                    return
                }
                
                completion(streamURL, duration)
            }
            task.resume()
        }
    }

    /**
     Retrieves track metadata from the playlist URL, builds the streaming URL,
     and loads the track into the AudioPlayerManager.
     */
    func getTrack(by trackId: String, title: String = "", completion: @escaping () -> Void) {
        // Cancel any existing request
        currentTask?.cancel()
        
        isLoading = true
        self.trackId = trackId
        
        fetchTrackURL(by: trackId) { [weak self] streamURL, duration in
            guard let self = self else { return }
            
            guard let streamURL = streamURL, let duration = duration else {
                self.cleanupAndComplete(completion: completion)
                return
            }
            
            self.trackDuration = duration
            self.trackTime = self.formatTrackTime(seconds: duration)
            
            AudioPlayerManager.shared.loadTrack(from: streamURL, duration: duration, title: title)
            self.cleanupAndComplete(completion: completion)
        }
    }
    
    private func cleanupAndComplete(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.currentTask = nil
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
