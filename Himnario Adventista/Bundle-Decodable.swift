//
//  Bundle-Decodable.swift
//  Concordancia
//
//  Created by Jose Pimentel on 11/20/24.
//

import Foundation

extension Bundle {
    func decode<T: Decodable>(_ file: String) -> T {
        // Locate the JSON file in the bundle
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }
        
        // Load the data from the file
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }
        
        // Create a JSONDecoder instance
        let decoder = JSONDecoder()
        
        // Decode the data into the specified type
        do {
            return try decoder.decode(T.self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("Decoding error: missing key '\(key.stringValue)' in \(file) – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            fatalError("Decoding error: type mismatch for type '\(type)' in \(file) – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("Decoding error: missing value for type '\(type)' in \(file) – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            fatalError("Decoding error: data corrupted in \(file) – \(context.debugDescription)")
        } catch {
            fatalError("Decoding error in \(file): \(error.localizedDescription)")
        }
    }
}
