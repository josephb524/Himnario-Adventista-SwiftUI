//
//  AudiusHostService.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 1/13/25.
//  Copyright © 2025 Jose Pimentel. All rights reserved.
//

import Foundation

/// A simple service to fetch the list of discovery hosts from Audius.
final class AudiusHostService {
    
    /// Fetches available Audius discovery hosts from https://api.audius.co
    /// and calls `completion` with one selected host or `nil` on failure.
    func fetchAudiusHost(completion: @escaping (String?) -> Void) {
        let urlString = "https://api.audius.co"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching hosts: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    print("No data returned from \(urlString)")
                    completion(nil)
                    return
                }
                
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    guard
                        let dict = jsonObject as? [String: Any],
                        let endpoints = dict["data"] as? [String],
                        !endpoints.isEmpty
                    else {
                        print("Could not parse endpoints from JSON or was empty.")
                        completion(nil)
                        return
                    }
                    
                    let selectedHost = endpoints[0]
                    print("Selected Audius Host: \(selectedHost)")
                    completion(selectedHost)
                } catch {
                    print("JSON parsing error: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
        task.resume()
    }
}
