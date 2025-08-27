//
//  ProgressBarTimer.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 1/22/22.
//  Updated for modern player apps on 3/25/25.
//

import Foundation
import AVFoundation
import Combine

class ProgressBarTimer: ObservableObject {
    static let instance = ProgressBarTimer()
    
    // MARK: - Published Properties
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0.0
    @Published var duration: TimeInterval = 0.0
    @Published var formattedCurrentTime: String = "0:00"
    @Published var formattedRemainingTime: String = "0:00"
    @Published var isDragging: Bool = false
    
    // MARK: - Private Properties
    private var timeObserver: Any?
    private var player: AVPlayer? {
        return AudioPlayerManager.shared.audioPlayer
    }
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotifications()
    }
    
    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Start observing player progress with high precision
    func startObserving() {
        removeTimeObserver()
        
        guard let player = player else { return }
        
        // High-frequency updates for smooth progress (60fps)
        let interval = CMTime(seconds: 1.0/60.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isDragging else { return }
            self.updateProgress(with: time)
        }
        
        // Observe duration changes
        observeDurationChanges()
    }
    
    /// Stop observing player progress
    func stopObserving() {
        removeTimeObserver()
    }
    
    /// Reset all progress values
    func reset() {
        DispatchQueue.main.async { [weak self] in
            self?.progress = 0.0
            self?.currentTime = 0.0
            self?.duration = 0.0
            self?.formattedCurrentTime = "0:00"
            self?.formattedRemainingTime = "0:00"
        }
    }
    
    /// Seek to specific progress (0.0 to 1.0)
    func seek(to progress: Double) {
        guard let player = player,
              duration > 0,
              progress >= 0.0 && progress <= 1.0 else { return }
        
        let targetTime = duration * progress
        let cmTime = CMTime(seconds: targetTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        isDragging = true
        
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isDragging = false
            }
        }
    }
    
    /// Seek to specific time in seconds
    func seek(toTime timeInterval: TimeInterval) {
        guard duration > 0 else { return }
        let progress = min(max(timeInterval / duration, 0.0), 1.0)
        seek(to: progress)
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        // Listen for player item changes
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                self?.handlePlaybackEnd()
            }
            .store(in: &cancellables)
        
        // Listen for player failures
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime)
            .sink { [weak self] notification in
                self?.handlePlaybackError(notification)
            }
            .store(in: &cancellables)
    }
    
    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    private func updateProgress(with time: CMTime) {
        guard time.isValid && !time.isIndefinite else { return }
        
        let currentTimeValue = time.seconds
        guard currentTimeValue.isFinite && currentTimeValue >= 0 else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.currentTime = currentTimeValue
            self.formattedCurrentTime = self.formatTime(currentTimeValue)
            
            if self.duration > 0 {
                self.progress = min(currentTimeValue / self.duration, 1.0)
                let remainingTime = max(self.duration - currentTimeValue, 0)
                self.formattedRemainingTime = "-\(self.formatTime(remainingTime))"
            }
        }
    }
    
    private func observeDurationChanges() {
        guard let player = player,
              let currentItem = player.currentItem else { return }
        
        // Observe duration using KVO
        currentItem.publisher(for: \.duration)
            .compactMap { duration -> TimeInterval? in
                guard duration.isValid && !duration.isIndefinite else { return nil }
                return duration.seconds
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] durationValue in
                guard let self = self, durationValue.isFinite && durationValue > 0 else { return }
                self.duration = durationValue
                self.formattedRemainingTime = "-\(self.formatTime(durationValue))"
            }
            .store(in: &cancellables)
        
        // Observe status changes
        currentItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .readyToPlay {
                    self?.updateInitialDuration()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateInitialDuration() {
        guard let player = player,
              let currentItem = player.currentItem else { return }
        
        let duration = currentItem.duration
        guard duration.isValid && !duration.isIndefinite else { return }
        
        let durationValue = duration.seconds
        guard durationValue.isFinite && durationValue > 0 else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.duration = durationValue
            self.formattedRemainingTime = "-\(self.formatTime(durationValue))"
        }
    }
    
    private func handlePlaybackEnd() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progress = 1.0
            self.currentTime = self.duration
            self.formattedCurrentTime = self.formatTime(self.duration)
            self.formattedRemainingTime = "-0:00"
        }
        
        // Auto-stop after completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AudioPlayerManager.shared.stop()
        }
    }
    
    private func handlePlaybackError(_ notification: Notification) {
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
            print("Playback error: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.reset()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        guard timeInterval.isFinite && timeInterval >= 0 else { return "0:00" }
        
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Legacy Support
extension ProgressBarTimer {
    /// Legacy method for compatibility - use startObserving() instead
    @available(*, deprecated, message: "Use startObserving() instead")
    func startTimer() {
        startObserving()
    }
    
    /// Legacy method for compatibility - use stopObserving() instead
    @available(*, deprecated, message: "Use stopObserving() instead")
    func stopTimer() {
        stopObserving()
    }
    
    /// Legacy method for compatibility - use reset() instead
    @available(*, deprecated, message: "Use reset() instead")
    func resetProgress() {
        reset()
    }
}
