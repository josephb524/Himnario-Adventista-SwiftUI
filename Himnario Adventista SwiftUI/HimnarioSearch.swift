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

        if let id = Int(query) {
            // Search by ID if the query is a number
            return himnos.filter { $0.id == id }
        } else {
            // Search by matching letters in title or himno (case-insensitive)
            return himnos.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.himno.localizedCaseInsensitiveContains(query)
            }
        }
    }
}
