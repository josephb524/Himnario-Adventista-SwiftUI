//
//  FavoritesManager.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/2/25.
//

import SwiftUI

class FavoritesManager: ObservableObject {
    @Published var favoriteHimnos: [Himnario] = [] {
        didSet {
            saveFavorites()
        }
    }
    
    init() {
        loadFavorites()
    }
    
    func addToFavorites(himno: Himnario) {
        if !favoriteHimnos.contains(where: { $0.id == himno.id && $0.himnarioVersion == himno.himnarioVersion }) {
            favoriteHimnos.append(himno)
        }
    }
    
    func removeFromFavorites(id: Int, himnarioVersion: String) {
        if let index = favoriteHimnos.firstIndex(where: { $0.id == id && $0.himnarioVersion == himnarioVersion }) {
            favoriteHimnos.remove(at: index)
        }
    }
    
    func isFavorite(id: Int, himnarioVersion: String) -> Bool {
        return favoriteHimnos.contains(where: { $0.id == id && $0.himnarioVersion == himnarioVersion })
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteHimnos) {
            UserDefaults.standard.set(data, forKey: "favoriteHimnos")
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favoriteHimnos"),
           let himnos = try? JSONDecoder().decode([Himnario].self, from: data) {
            favoriteHimnos = himnos
        }
    }
}
