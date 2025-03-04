//
//  ProgressBarTimer.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 1/22/22.
//  Copyright © 2022 Jose Pimentel. All rights reserved.
//

import UIKit
import AVFoundation

final class ProgressBarTimer {
    
    static let instance = ProgressBarTimer()
    
    /// The underlying timer that ticks every second to update the progress bar.
    private(set) var timer = Timer()
    
    /// The current fractional progress (0.0 to 1.0) displayed in the UIProgressView.
    private(set) var progressBarProgress: Float = 0.0
    
    /// References to UI elements updated every second.
    private weak var progressBar: UIProgressView?
    private weak var playPauseButton: UIButton?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /**
     Assigns UI elements (progress bar, play/pause button) that we should update.
     */
    func setProgressUI(progressBar: UIProgressView, playPauseButton: UIButton) {
        self.progressBar = progressBar
        self.playPauseButton = playPauseButton
    }
    
    /**
     Starts a 1-second repeating timer that calls the given selector on the target.
     */
    func startTimer(target: Any, selector: Selector) {
        stopTimer() // Invalidate any existing timer.
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: target,
            selector: selector,
            userInfo: nil,
            repeats: true
        )
    }
    
    /**
     Stops the repeating timer.
     */
    func stopTimer() {
        timer.invalidate()
    }
    
    /**
     Called every second by the timer.
     Updates the progress bar based on the AVPlayer's current time vs. total track duration.
     */
    func updateProgress() {
        guard let audioPlayer = AudioPlayerManager.shared.getAudioPlayer() else {
            return
        }
        
        let currentTime = audioPlayer.currentTime().seconds
        guard currentTime > 0 else {
            return
        }
        
        let totalDuration = Float(AudioPlayerManager.shared.trackDuration)
        guard totalDuration > 0 else {
            return
        }
        
        // If we've reached (or nearly reached) the end of the track, finish up.
        if Int(currentTime) + 1 >= AudioPlayerManager.shared.trackDuration {
            finishPlayback()
            return
        }
        
        progressBarProgress = Float(Int(currentTime) + 1) / totalDuration
        CoritosViewController.progressBarCount += 1
        progressBar?.progress = progressBarProgress
    }
    
    /**
     Resets the progress bar to 0.0 immediately.
     */
    func resetProgress() {
        progressBarProgress = 0.0
        progressBar?.progress = 0.0
    }
    
    // MARK: - Private
    
    /**
     Called when the track is finished.
     Resets UI, stops the timer, and updates app state.
     */
    private func finishPlayback() {
        progressBar?.progress = 1.0
        progressBarProgress = 0.0
        
        CoritosViewController.progressBarCount = 0
        CoritosViewController.launchBefore = false
        CoritosViewController.isStartingSong = true
        
        playPauseButton?.setImage(
            UIImage(
                systemName: "play.fill",
                withConfiguration: UIImage.SymbolConfiguration(textStyle: .largeTitle)
            ),
            for: .normal
        )
        
        stopTimer()
        NetworkService.shared.setURL(url: "123")  // Example: Reset host URL if needed.
        progressBar?.progress = 0.0
    }
}
