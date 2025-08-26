//
//  Himnario.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 2/26/25.
//


struct Himnario: Codable, Identifiable {
    let numericId: Int
    let title: String
    let himno: String
    let himnoID: String
    let pistaID: String
    let himnarioVersion: String

    // Computed property for unique identification across collections
    var id: String {
        return "\(himnarioVersion)_\(numericId)"
    }

    // Map the JSON key "HimnarioVersion" to our property name
    private enum CodingKeys: String, CodingKey {
        case numericId = "id"
        case title, himno, himnoID, pistaID
        case himnarioVersion = "HimnarioVersion"
    }
}
