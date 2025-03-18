//
//  ProgressBarTimer.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 1/22/22.
//  Updated for SwiftUI on 3/25/25.
//

import Foundation
import AVFoundation

class ProgressBarTimer: ObservableObject {
    static let instance = ProgressBarTimer()
    
    @Published var progress: Float = 0.0
    var timer: Timer?
    
    private init() {}
    
    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateProgress() {
        guard let audioPlayer = AudioPlayerManager.shared.getAudioPlayer() else {
            return
        }
        let currentTime = audioPlayer.currentTime().seconds
        guard currentTime > 0 else { return }
        let totalDuration = Float(AudioPlayerManager.shared.trackDuration)
        guard totalDuration > 0 else { return }
        if Int(currentTime) + 1 >= AudioPlayerManager.shared.trackDuration {
            finishPlayback()
            return
        }
        let newProgress = Float(Int(currentTime) + 1) / totalDuration
        DispatchQueue.main.async {
            self.progress = newProgress
        }
    }
    
    func resetProgress() {
        DispatchQueue.main.async {
            self.progress = 0.0
        }
    }
    
    private func finishPlayback() {
        DispatchQueue.main.async {
            self.progress = 1.0
        }
        stopTimer()
        NetworkService.shared.setURL(url: "123")
        DispatchQueue.main.async {
            self.progress = 0.0
        }
    }
}
