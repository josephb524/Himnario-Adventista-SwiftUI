//
//  AudioBrain.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 8/22/21.
//  Copyright © 2021 Jose Pimentel. All rights reserved.
//

import UIKit

/**
 A class that coordinates retrieving track metadata (via `getTrack(...)`),
 building the stream URL, and controlling playback.
 */
final class AudioBrain {
    
    // MARK: - Singleton
    static let instance = AudioBrain()
    
    // MARK: - Services
    let playlistService = PlaylistService()
    
    // MARK: - Properties
    var trackId: String = ""
    var trackDuration: Int = 0
    var trackTime: String = ""
    
    var coritoFavorito: String = ""
    var isVoice: Bool = false
    var indexCorito: Int = 0  // Use this property consistently
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Prepares the requirements for a certain corito.
    func audioRequirement(coritoFav: String, indexC: Int, isVocal: Bool) {
        coritoFavorito = coritoFav
        indexCorito = indexC  // Now we use the same index everywhere.
        self.isVoice = isVocal
    }
    
    /**
     Retrieves the track metadata from the playlist URL, then builds the streaming URL.
     Once the correct stream URL is created, it loads the track into the AudioPlayerManager.
     
     - Parameter completion: Called after the track is loaded (or on error).
     */
    func getTrack(completion: @escaping () -> Void) {
        // 1. Get the playlist URL based on the category and type.
        playlistService.findPlaylistURL(
            coritoFavorito: coritoFavorito,
            isVoice: isVoice,
            indexCorito: indexCorito
        ) { [weak self] playlistURL in
            guard let self = self else { return }
            guard let finalURL = playlistURL else {
                debugPrint("Could not get a valid playlist URL.")
                DispatchQueue.main.async { completion() }
                return
            }
            
            // 2. Set the URL in the network service (to later fetch track metadata).
            NetworkService.shared.setURL(url: finalURL)
            
            // 3. Retrieve track metadata (himnos data).
            NetworkService.shared.getHimnos { dataAPI in
                let dataIndex = self.indexCorito
                guard dataIndex < dataAPI.data.count else {
                    debugPrint("Index out of range in dataAPI.")
                    DispatchQueue.main.async { completion() }
                    return
                }
                
                let himnoData = dataAPI.data[dataIndex]
                self.trackId = himnoData.id
                self.trackDuration = himnoData.duration
                self.trackTime = self.formatTrackTime(seconds: himnoData.duration)
                
                if CoritosViewController.isStartingSong {
                    CoritosViewController.isStartingSong = false
                    ProgressBarTimer.instance.resetProgress()
                }
                
                // 4. Now build the actual streaming URL using the trackId.
                self.playlistService.hostService.fetchAudiusHost { resolvedHost in
                    let host = resolvedHost ?? "https://audius-discovery-3.altego.net"
                    let streamURLString = "\(host)/v1/tracks/\(self.trackId)/stream?app_name=HimnarioViejo"
                    
                    guard let encodedStreamURLString = streamURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                          let streamURL = URL(string: encodedStreamURLString) else {
                        debugPrint("Invalid streaming URL.")
                        DispatchQueue.main.async { completion() }
                        return
                    }
                    
                    // Load the track into the AudioPlayerManager (pass trackDuration for progress tracking)
                    AudioPlayerManager.shared.loadTrack(from: streamURL, duration: self.trackDuration)
                    CoritosViewController.indexCoritoPlaying = self.indexCorito
                    
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
    
    /**
     Helper to format the track's total seconds into "mm:ss".
     */
    private func formatTrackTime(seconds: Int) -> String {
        let minutes = seconds / 60 % 60
        let secs = seconds % 60
        return String(format: "%02i:%02i", minutes, secs)
    }
    
    // If not used, you may remove the setAudioURL() method.
}
