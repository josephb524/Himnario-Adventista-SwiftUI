//
//  SupportPromptManager.swift
//  Himnario Adventista SwiftUI
//
//  Manager for showing periodic support prompts to non-subscribed users

import SwiftUI
import StoreKit

@MainActor
class SupportPromptManager: ObservableObject {
    static let shared = SupportPromptManager()
    
    private init() {}
    
    // MARK: - Support Tracking Keys
    private enum SupportKeys {
        static let appLaunchCount = "supportPrompt_appLaunchCount"
        static let appLaunchesSinceLastPrompt = "supportPrompt_appLaunchesSinceLastPrompt"
        static let playlistsCreatedCount = "supportPrompt_playlistsCreatedCount"
        static let lastSupportPromptDate = "supportPrompt_lastPromptDate"
        static let userDismissedSupportCount = "supportPrompt_dismissedCount"
        static let userInteractedWithSupport = "supportPrompt_userInteracted"
        static let lastDismissType = "supportPrompt_lastDismissType"
    }
    
    // MARK: - Smart Thresholds
    // Show on every launch by default, but respect "No, gracias" with a longer delay
    private let defaultAppLaunchTrigger = 1     // Show after every app launch (default/"Más tarde")
    private let noThanksAppLaunchTrigger = 5    // Show after 5 app launches if user said "No, gracias"
    
    // MARK: - UserDefaults Properties
    @AppStorage(SupportKeys.appLaunchCount) private var appLaunchCount = 0
    @AppStorage(SupportKeys.appLaunchesSinceLastPrompt) private var appLaunchesSinceLastPrompt = 0
    @AppStorage(SupportKeys.playlistsCreatedCount) private var playlistsCreatedCount = 0
    @AppStorage(SupportKeys.userDismissedSupportCount) private var userDismissedSupportCount = 0
    @AppStorage(SupportKeys.userInteractedWithSupport) private var userInteractedWithSupport = false
    @AppStorage(SupportKeys.lastDismissType) private var lastDismissType = ""
    
    private var lastSupportPromptDate: Date? {
        get {
            if let timeInterval = UserDefaults.standard.object(forKey: SupportKeys.lastSupportPromptDate) as? TimeInterval {
                return Date(timeIntervalSince1970: timeInterval)
            }
            return nil
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: SupportKeys.lastSupportPromptDate)
            } else {
                UserDefaults.standard.removeObject(forKey: SupportKeys.lastSupportPromptDate)
            }
        }
    }
    
    // MARK: - Tracking Methods
    func trackAppLaunch() {
        appLaunchCount += 1
        appLaunchesSinceLastPrompt += 1
        checkForSupportPrompt()
    }
    
    func trackPlaylistCreated() {
        playlistsCreatedCount += 1
        checkForSupportPrompt()
    }
    
    // MARK: - Support Prompt Logic
    func shouldShowSupportPrompt() -> Bool {
        // Never show to active subscribers
        // NOTE: This checks LIVE subscription status - if subscription expires,
        // isSubscribed becomes false and prompts will resume automatically
        if SubscriptionManager.shared.isSubscribed {
            return false
        }
        
        // Determine threshold based on last dismiss type
        let threshold: Int
        if lastDismissType == "no_thanks" {
            // User said "No, gracias" - be more respectful, wait for 5 launches
            threshold = noThanksAppLaunchTrigger
        } else {
            // User said "Más tarde" or first time - show every launch
            threshold = defaultAppLaunchTrigger
        }
        
        // Check if user has launched the app enough times since last prompt
        let hasEnoughLaunches = appLaunchesSinceLastPrompt >= threshold
        
        return hasEnoughLaunches
    }
    
    private func checkForSupportPrompt() {
        if shouldShowSupportPrompt() {
            // Delay showing the prompt by 1 second to not interrupt user flow
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showSupportPrompt()
            }
        }
    }
    
    // MARK: - Support Prompt Methods
    private func showSupportPrompt() {
        // Reset the counter when showing the prompt
        appLaunchesSinceLastPrompt = 0
        lastSupportPromptDate = Date()
        SettingsManager.shared.showSupportPrompt = true
    }
    
    func userDismissedSupport(type: DismissType) {
        userDismissedSupportCount += 1
        
        // Store the dismiss type to determine next threshold
        switch type {
        case .noThanks:
            lastDismissType = "no_thanks"
        case .masTarde:
            lastDismissType = "mas_tarde"
        }
        
        // Reset counter so it starts counting from 0
        appLaunchesSinceLastPrompt = 0
        lastSupportPromptDate = Date()
    }
    
    func userOpenedSupport() {
        // When user opens support screen, reset counter
        // Give them credit for engaging with the prompt
        appLaunchesSinceLastPrompt = 0
        lastSupportPromptDate = Date()
    }
    
    
}

// MARK: - Dismiss Type Enum
enum DismissType {
    case noThanks   // "No, gracias" - wait 5 app launches
    case masTarde   // "Más tarde" - wait 1 app launch
}

