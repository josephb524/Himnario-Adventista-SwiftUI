//
//  PromoBannerManager.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/20/26.
//

import Foundation
import Combine
import UIKit

class PromoBannerManager: ObservableObject {
    static let shared = PromoBannerManager()
    
    @Published var banners: [PromoBanner] = []
    
    private let bannerURL = URL(string: "https://raw.githubusercontent.com/josephb524/Remote-Promo-Banner-Json/main/PromoBannerSpanish.json")!
    private let cacheKey = "cachedPromoBanners"
    
    /// Custom URLSession that bypasses all caching for instant updates
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }()
    
    private init() {
        // Load cached banners immediately so they're available offline
        loadCachedBanners()
        
        // Listen for app returning to foreground to re-fetch
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public
    
    func fetchBanners() {
        // Append a timestamp to bust GitHub's CDN cache (it ignores client-side cache policies)
        let cacheBustedURL = URL(string: "\(bannerURL.absoluteString)?t=\(Int(Date().timeIntervalSince1970))")!
        var request = URLRequest(url: cacheBustedURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("[PromoBannerManager] Fetch failed: \(error?.localizedDescription ?? "HTTP error")")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PromoBannerResponse.self, from: data)
                let activeBanners = decoded.banners.filter { $0.isActive }

                // Cache the raw JSON for offline use
                UserDefaults.standard.set(data, forKey: self.cacheKey)

                DispatchQueue.main.async {
                    self.banners = activeBanners
                    print("[PromoBannerManager] Loaded \(activeBanners.count) active banner(s)")
                }
            } catch {
                print("[PromoBannerManager] JSON decode error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.banners = []
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Foreground Refresh
    
    @objc private func appDidBecomeActive() {
        fetchBanners()
    }
    
    // MARK: - Caching
    
    private func cacheBannerData(_ data: Data) {
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
    
    private func loadCachedBanners() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }
        
        do {
            let decoded = try JSONDecoder().decode(PromoBannerResponse.self, from: data)
            self.banners = decoded.banners.filter { $0.isActive }
        } catch {
            print("[PromoBannerManager] Cache decode failed: \(error.localizedDescription)")
        }
    }
}
