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

final class AudioPlayerManager {
    static let shared = AudioPlayerManager()
    
    var audioPlayer: AVPlayer?
    
    private(set) var coritoRate: Float = 0.0
    var trackDuration: Int = 0
    var currentTrackTitle: String = ""
    var playbackContext: PlaybackContext = .individual
    
    private init() {
        setupRemoteTransportControls()
    }
    
    func loadTrack(from url: URL, duration: Int? = nil, title: String = "") {
        // Stop observing old player before swap
        ProgressBarTimer.instance.stopObserving()
        
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.automaticallyWaitsToMinimizeStalling = false
        currentTrackTitle = title
        if let dur = duration {
            trackDuration = dur
        }
        updateNowPlayingInfo()
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
        audioPlayer?.seek(to: .zero)
        coritoRate = 0.0
        ProgressBarTimer.instance.stopObserving()
        ProgressBarTimer.instance.reset()
        clearNowPlayingInfo()
        //AudioBrain.instance.trackTime = ""
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
