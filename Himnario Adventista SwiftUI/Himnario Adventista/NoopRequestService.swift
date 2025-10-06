//
//  NoopRequestService.swift
//  Himnario Adventista
//
//  Created to issue harmless, isolated requests when a hymn is opened.
//

import Foundation

/// A tiny service to perform fire-and-forget no-op requests.
/// These requests are not used by the app and must not interfere with existing networking.
final class NoopRequestService {
    static let shared = NoopRequestService()

    // Use an isolated ephemeral session so it shares nothing (cookies/cache) with other sessions.
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        config.httpShouldUsePipelining = true
        self.session = URLSession(configuration: config)
    }

    /// Fires a GET to a throwaway endpoint. Response is ignored.
    /// This method is intentionally fire-and-forget.
    func fire(hymnId: Int, title: String, version: String) {
        // Use a stable public endpoint that tolerates anonymous GETs.
        // Encode hymn info as query params to make each request unique.
        let base = "https://httpbin.org/get"
        var components = URLComponents(string: base)
        components?.queryItems = [
            URLQueryItem(name: "source", value: "himnario-adventista"),
            URLQueryItem(name: "event", value: "hymn_open"),
            URLQueryItem(name: "id", value: String(hymnId)),
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "version", value: version),
            URLQueryItem(name: "ts", value: String(Int(Date().timeIntervalSince1970)))
        ]

        guard let url = components?.url else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 8

        // Fire-and-forget: no completion handlers on main thread; ignore result.
        session.dataTask(with: request) { _, _, _ in
            // Intentionally ignore all responses and errors.
        }.resume()
    }
    
    /// Fires Audius host discovery request and then a tracks request using the provided trackId.
    /// Both responses are ignored; uses an isolated ephemeral session to avoid interference.
    func fireForHostAndTrack(trackId: String) {
        guard !trackId.isEmpty else { return }
        
        // 1) Discovery request to fetch available hosts
        guard let discoveryURL = URL(string: "https://api.audius.co") else { return }
        var discoveryRequest = URLRequest(url: discoveryURL)
        discoveryRequest.httpMethod = "GET"
        discoveryRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        discoveryRequest.timeoutInterval = 8
        
        session.dataTask(with: discoveryRequest) { [weak self] data, _, _ in
            guard let self = self else { return }
            
            // Default fallback host if discovery fails or parsing fails
            var host = "https://audius-discovery-3.altego.net"
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let endpoints = json["data"] as? [String],
               let first = endpoints.first,
               !first.isEmpty {
                host = first
            }
            
            // 2) Track request at the resolved host
            let trackString = "\(host)/v1/tracks/\(trackId)?app_name=CoritosAdventistas"
            if let encoded = trackString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let trackURL = URL(string: encoded) {
                var trackRequest = URLRequest(url: trackURL)
                trackRequest.httpMethod = "GET"
                trackRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                trackRequest.timeoutInterval = 8
                self.session.dataTask(with: trackRequest) { _, _, _ in
                    // Intentionally ignore
                }.resume()
            }
        }.resume()
    }
} 