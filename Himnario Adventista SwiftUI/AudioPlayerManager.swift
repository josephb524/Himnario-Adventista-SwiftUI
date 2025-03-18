//
//  AudioPlayerManager.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 8/22/21.
//  Updated for modern player apps on 3/25/25.
//

import AVFoundation
import SwiftUI

final class AudioPlayerManager {
    static let shared = AudioPlayerManager()
    
    var audioPlayer: AVPlayer?
    
    private(set) var coritoRate: Float = 0.0
    var trackDuration: Int = 0
    
    private init() {}
    
    func loadTrack(from url: URL, duration: Int? = nil) {
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.automaticallyWaitsToMinimizeStalling = false
        if let dur = duration {
            trackDuration = dur
        }
    }
    
    func playPause() {
        guard let player = audioPlayer else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            ProgressBarTimer.instance.stopTimer()
        } else {
            configureAudioSession()
            player.play()
            ProgressBarTimer.instance.startTimer()
        }
        coritoRate = player.rate
    }
    
    func play() {
        guard let player = audioPlayer else { return }
        configureAudioSession()
        player.play()
        coritoRate = player.rate
        ProgressBarTimer.instance.startTimer()
    }
    
    func stop() {
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
        coritoRate = 0.0
        ProgressBarTimer.instance.stopTimer()
        ProgressBarTimer.instance.resetProgress()
        AudioBrain.instance.trackTime = ""
    }
    
    func getAudioPlayer() -> AVPlayer? {
        return audioPlayer
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            debugPrint("Audio session error:", error.localizedDescription)
        }
    }
}
