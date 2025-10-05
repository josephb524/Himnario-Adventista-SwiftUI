//
//  NetworkService.swift
//  WeatherApp
//
//  Created by Jose Pimentel on 9/1/21.
//

import Foundation

/// A singleton networking service for fetching `Himnos` data from a remote API.
final class NetworkService {
    
    static let shared = NetworkService()
    
    /// The base URL that determines which playlist we’re fetching.
    var URL_BASE = "123"
    
    private let session = URLSession(configuration: .default)
    
    private init() {}
    
    /**
     Sets the base URL for subsequent calls.
     */
    func setURL(url: String) {
        URL_BASE = url
    }
    
    /**
     Fetches himnos data (an array of tracks) from the current `URL_BASE`.
     - Parameters:
       - onSuccess: Closure with a `DataAPI` object when the fetch succeeds.
       - onError: Closure with an error message string when the fetch fails.
     */
    func getHimnos(onSuccess: @escaping (DataAPI) -> Void,
                   onError: @escaping (String) -> Void) {
        guard let url = URL(string: URL_BASE) else {
            onError("Invalid URL base: \(URL_BASE)")
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                
                if let error = error {
                    onError(error.localizedDescription)
                    return
                }
                
                guard let data = data,
                      let httpResp = response as? HTTPURLResponse else {
                    onError("Invalid data or response.")
                    return
                }
                
                do {
                    if httpResp.statusCode == 200 {
                        let decoded = try JSONDecoder().decode(DataAPI.self, from: data)
                        onSuccess(decoded)
                    } else {
                        let apiErr = try JSONDecoder().decode(APIError.self, from: data)
                        onError(apiErr.message)
                    }
                } catch {
                    onError(error.localizedDescription)
                }
            }
        }
        
        task.resume()
    }
}
