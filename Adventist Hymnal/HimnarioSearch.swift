//
//  SearchHimnoBrain.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 2/27/25.
//


import Foundation

struct HimnarioSearch {
    func search(query: String, himnos: [Himnario]) -> [Himnario] {
        guard !query.isEmpty else { return [] }
        
        // Normalize query for better matching
        let processedQuery = query
            .trimmingCharacters(in: .whitespaces)
            .normalizedForSearch()
        
        return himnos.filter { himno in
            // Normalize text fields for comparison
            let normalizedTitle = himno.title.normalizedForSearch()
            let normalizedHimno = himno.himno.normalizedForSearch()
            
            // Check text matches with special character handling
            let textMatch = normalizedTitle.contains(processedQuery) ||
                            normalizedHimno.contains(processedQuery)
            
            // Check numeric prefix match
            let idMatch = String(himno.numericId).starts(with: query)
            
            return textMatch || idMatch
        }
    }
}

extension String {
    func normalizedForSearch() -> String {
        self.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
            .lowercased()
    }
}
