//
//  PromoBanner.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/20/26.
//

import Foundation

struct PromoBanner: Codable, Identifiable {
    let id: String
    let imageURL: String
    let destinationURL: String
    let title: String
    let subtitle: String
    let isActive: Bool
}

struct PromoBannerResponse: Codable {
    let banners: [PromoBanner]
}
