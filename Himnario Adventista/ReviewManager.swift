//
//  ReviewManager.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/20/25.
//

import SwiftUI
import StoreKit

class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    
    private init() {}
    
    // MARK: - Review Tracking Keys
    private enum ReviewKeys {
        static let hasRequestedReview = "hasRequestedReview"
        static let appLaunchCount = "appLaunchCount"
        static let hymnsViewedCount = "hymnsViewedCount"
        static let favoritesAddedCount = "favoritesAddedCount"
        static let lastReviewRequestDate = "lastReviewRequestDate"
        static let userDismissedReviewCount = "userDismissedReviewCount"
    }
    
    // MARK: - Review Thresholds
    private let minimumLaunchCount = 3
    private let minimumHymnsViewed = 5
    private let minimumFavoritesAdded = 2
    private let daysBetweenReviewRequests = 90
    private let maxDismissCount = 2
    
    // MARK: - UserDefaults Properties
    @AppStorage(ReviewKeys.hasRequestedReview) private var hasRequestedReview = false
    @AppStorage(ReviewKeys.appLaunchCount) private var appLaunchCount = 0
    @AppStorage(ReviewKeys.hymnsViewedCount) private var hymnsViewedCount = 0
    @AppStorage(ReviewKeys.favoritesAddedCount) private var favoritesAddedCount = 0
    @AppStorage(ReviewKeys.userDismissedReviewCount) private var userDismissedReviewCount = 0
    
    private var lastReviewRequestDate: Date? {
        get {
            if let timeInterval = UserDefaults.standard.object(forKey: ReviewKeys.lastReviewRequestDate) as? TimeInterval {
                return Date(timeIntervalSince1970: timeInterval)
            }
            return nil
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: ReviewKeys.lastReviewRequestDate)
            } else {
                UserDefaults.standard.removeObject(forKey: ReviewKeys.lastReviewRequestDate)
            }
        }
    }
    
    // MARK: - Tracking Methods
    func trackAppLaunch() {
        appLaunchCount += 1
        checkForReviewPrompt()
    }
    
    func trackHymnoViewed() {
        hymnsViewedCount += 1
        checkForReviewPrompt()
    }
    
    func trackFavoriteAdded() {
        favoritesAddedCount += 1
        checkForReviewPrompt()
    }
    
    // MARK: - Review Logic
    func shouldShowReviewPrompt() -> Bool {
        // Don't show if user has dismissed too many times
        if userDismissedReviewCount >= maxDismissCount {
            return false
        }
        
        // Check if enough time has passed since last request
        if let lastDate = lastReviewRequestDate {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSinceLastRequest < daysBetweenReviewRequests {
                return false
            }
        }
        
        // Check if user has met the engagement thresholds
        let hasMinimumLaunches = appLaunchCount >= minimumLaunchCount
        let hasMinimumHymnsViewed = hymnsViewedCount >= minimumHymnsViewed
        let hasMinimumFavorites = favoritesAddedCount >= minimumFavoritesAdded
        
        return hasMinimumLaunches && hasMinimumHymnsViewed && hasMinimumFavorites
    }
    
    private func checkForReviewPrompt() {
        if shouldShowReviewPrompt() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Use Apple's native review prompt for automatic requests
                self.showNativeReviewPrompt()
            }
        }
    }
    
    // MARK: - Review Prompt Methods
    
    // For automatic prompts - use Apple's native prompt
    private func showNativeReviewPrompt() {
        lastReviewRequestDate = Date()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    // For manual prompts - use custom prompt
    func showCustomReviewPrompt() {
        SettingsManager.shared.showReviewPrompt = true
    }
    
    func userDismissedReview() {
        userDismissedReviewCount += 1
        lastReviewRequestDate = Date()
    }
    
    func userLeftReview() {
        hasRequestedReview = true
        lastReviewRequestDate = Date()
    }
    
    // MARK: - Debug Methods (for testing)
    #if DEBUG
    func resetReviewTracking() {
        hasRequestedReview = false
        appLaunchCount = 0
        hymnsViewedCount = 0
        favoritesAddedCount = 0
        userDismissedReviewCount = 0
        lastReviewRequestDate = nil
    }
    
    func forceShowReview() {
        showCustomReviewPrompt()
    }
    #endif
} 