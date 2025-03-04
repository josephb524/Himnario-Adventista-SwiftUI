//
//  AudioPlayerManager.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 1/14/25.
//  Copyright © 2025 Jose Pimentel. All rights reserved.
//

import AVFoundation
import UIKit

/// A manager that handles audio playback for a single track.
final class AudioPlayerManager {
    
    // MARK: - Singleton
    static let shared = AudioPlayerManager()
    
    // MARK: - Private Properties
    var audioPlayer: AVPlayer?
    
    // MARK: - Public Properties
    private(set) var coritoRate: Float = 0.0
    var trackDuration: Int = 0  // Set when loading the track.
    
    // MARK: - Initializer
    private init() {}
    
    // MARK: - Public Methods
    
    /**
     Loads a track from the provided streaming URL into the AVPlayer.
     
     - Parameters:
       - url: The direct streaming URL of the track.
       - duration: The total track duration in seconds (optional).
     */
    func loadTrack(from url: URL, duration: Int? = nil) {
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.automaticallyWaitsToMinimizeStalling = false
        if let dur = duration {
            trackDuration = dur
        }
    }
    
    /**
     Toggles between playing and pausing the loaded track.
     */
    func playPause() {
        guard let player = audioPlayer else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
            ProgressBarTimer.instance.stopTimer()
        } else {
            configureAudioSession()
            player.play()
            ProgressBarTimer.instance.startTimer(
                target: self,
                selector: #selector(updateProgressBar)
            )
        }
        
        coritoRate = player.rate
    }
    
    /**
     Immediately starts playback after loading a track.
     */
    func play() {
        guard let player = audioPlayer else { return }
        configureAudioSession()
        player.play()
        coritoRate = player.rate
        ProgressBarTimer.instance.startTimer(
            target: self,
            selector: #selector(updateProgressBar)
        )
    }
    
    /**
     Stops playback entirely and resets progress.
     */
    func stop() {
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)  // Reset playback to the beginning
        coritoRate = 0.0
        ProgressBarTimer.instance.stopTimer()
        ProgressBarTimer.instance.resetProgress()  // Optionally reset the progress bar
    }
    
    /**
     Returns the current AVPlayer instance.
     */
    func getAudioPlayer() -> AVPlayer? {
        return audioPlayer
    }
    
    // MARK: - Private
    
    /**
     Called by the timer every second to update playback progress.
     */
    @objc func updateProgressBar() {
        ProgressBarTimer.instance.updateProgress()
    }
    
    /**
     Configures the audio session to allow playback in silent mode.
     */
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            debugPrint("Audio session error:", error.localizedDescription)
        }
    }
}
