//
//  AudioPlayerManager.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 8/22/21.
//  Updated for modern player apps on 3/25/25.
//

import AVFoundation
import SwiftUI
import MediaPlayer

enum PlaybackContext {
    case individual  // Single hymn from HimnoDetailView
    case playlist    // From playlist playback
}

final class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()
    
    @Published var audioPlayer: AVQueuePlayer?
    
    private(set) var coritoRate: Float = 0.0
    var trackDuration: Int = 0
    var currentTrackTitle: String = ""
    var playbackContext: PlaybackContext = .individual
    
    private init() {
        setupRemoteTransportControls()
    }
    
    func loadTrack(from url: URL, duration: Int? = nil, title: String = "") {
        print("AudioPlayerManager: Loading track \(title)")
        // Stop observing old player before swap
        ProgressBarTimer.instance.stopObserving()
        
        // Ensure player is paused before modifying queue
        audioPlayer?.pause()
        
        let item = AVPlayerItem(url: url)
        if audioPlayer == nil {
            audioPlayer = AVQueuePlayer(items: [item])
        } else {
            audioPlayer?.removeAllItems()
            if audioPlayer?.canInsert(item, after: nil) == true {
                audioPlayer?.insert(item, after: nil)
            } else {
                // Fallback: recreate player if insertion fails
                audioPlayer = AVQueuePlayer(items: [item])
            }
        }
        
        audioPlayer?.automaticallyWaitsToMinimizeStalling = false
        currentTrackTitle = title
        if let dur = duration {
            trackDuration = dur
        }
        updateNowPlayingInfo()
    }
    
    func appendTrack(url: URL) {
        print("AudioPlayerManager: Appending track")
        let item = AVPlayerItem(url: url)
        if audioPlayer == nil {
            audioPlayer = AVQueuePlayer(items: [item])
        } else {
            if audioPlayer?.canInsert(item, after: nil) == true {
                audioPlayer?.insert(item, after: nil)
            } else {
                print("AudioPlayerManager: Failed to append track")
            }
        }
    }
    
    func playPause() {
        guard let player = audioPlayer else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            ProgressBarTimer.instance.stopObserving()
        } else {
            configureAudioSession()
            player.play()
            ProgressBarTimer.instance.startObserving()
        }
        coritoRate = player.rate
        updateNowPlayingInfo()
    }
    
    func play() {
        guard let player = audioPlayer else { return }
        configureAudioSession()
        player.play()
        coritoRate = player.rate
        ProgressBarTimer.instance.startObserving()
        updateNowPlayingInfo()
    }
    
    func stop() {
        audioPlayer?.pause()
        audioPlayer?.removeAllItems()
        coritoRate = 0.0
        ProgressBarTimer.instance.stopObserving()
        ProgressBarTimer.instance.reset()
        clearNowPlayingInfo()
        //AudioBrain.instance.trackTime = ""
    }
    
    func clearQueue(keepCurrent: Bool = true) {
        guard let player = audioPlayer else { return }
        if keepCurrent {
            let items = player.items()
            // Remove all items except the first one (current)
            if items.count > 1 {
                for i in 1..<items.count {
                    player.remove(items[i])
                }
            }
        } else {
            player.removeAllItems()
        }
    }
    
    func getAudioPlayer() -> AVPlayer? {
        return audioPlayer
    }
    
    func setPlaybackContext(_ context: PlaybackContext) {
        playbackContext = context
    }
    
    private func configureAudioSession() {
        do {
            // Configure for background playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            debugPrint("Audio session error:", error.localizedDescription)
        }
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Enable play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        // Enable pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.audioPlayer?.pause()
            ProgressBarTimer.instance.stopTimer()
            self?.updateNowPlayingInfo()
            return .success
        }
        
        // Enable stop command
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }
        
        // Disable other commands we don't support
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrackTitle.isEmpty ? "Himnario Adventista" : currentTrackTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Himnario Adventista"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Himnos"
        
        if let player = audioPlayer {
            let currentTime = CMTimeGetSeconds(player.currentTime())
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            
            if trackDuration > 0 {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Double(trackDuration)
            }
            
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
