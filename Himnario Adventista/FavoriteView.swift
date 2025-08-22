//
//  FavoriteView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/2/25.
//

import SwiftUI

struct FavoriteView: View {
    @EnvironmentObject var playbackState: AudioPlaybackState
    @EnvironmentObject var favoritesManager: FavoritesManager
    @State private var searchText = ""
    @State private var isSearching = false
    let himnoSearch: HimnarioSearch = HimnarioSearch()
    @State private var himnoSearchResult: [Himnario] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Favoritos")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            if !favoritesManager.favoriteHimnos.isEmpty {
                                Text("\(favoritesManager.favoriteHimnos.count) himnos guardados")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        
                        // Heart icon with count
                        if !favoritesManager.favoriteHimnos.isEmpty {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if !favoritesManager.favoriteHimnos.isEmpty {
                        SearchBar(text: $searchText, onCommit: {
                            himnoSearchResult = himnoSearch.search(query: searchText, himnos: favoritesManager.favoriteHimnos)
                            isSearching = !searchText.isEmpty
                        }, onClear: {
                            searchText = ""
                            isSearching = false
                            himnoSearchResult = []
                        })
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                // Content
                if favoritesManager.favoriteHimnos.isEmpty {
                    // Beautiful empty state
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.red.opacity(0.2), Color.red.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "heart")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                        }
                        
                        VStack(spacing: 12) {
                            Text("No hay favoritos aún")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Toca el ícono de estrella en cualquier himno para agregarlo a tus favoritos")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    // Favorites list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if isSearching {
                                if himnoSearchResult.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 48))
                                            .foregroundColor(.gray)
                                        Text("No se encontraron himnos")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.top, 60)
                                } else {
                                    ForEach(himnoSearchResult) { himno in
                                        NavigationLink(destination: HimnoDetailView(himno: himno)
                                            .environmentObject(favoritesManager)
                                            .environmentObject(playbackState)) {
                                            HymnRowView(himno: himno)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .swipeActions(edge: .trailing) {
                                            Button("Eliminar", role: .destructive) {
                                                favoritesManager.removeFromFavorites(id: himno.id, himnarioVersion: himno.himnarioVersion)
                                            }
                                        }
                                    }
                                }
                            } else {
                                ForEach(favoritesManager.favoriteHimnos) { himno in
                                    NavigationLink(destination: HimnoDetailView(himno: himno)
                                        .environmentObject(favoritesManager)
                                        .environmentObject(playbackState)) {
                                        HymnRowView(himno: himno)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .swipeActions(edge: .trailing) {
                                        Button("Eliminar", role: .destructive) {
                                            favoritesManager.removeFromFavorites(id: himno.id, himnarioVersion: himno.himnarioVersion)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func delete(at offsets: IndexSet) {
        offsets.map { favoritesManager.favoriteHimnos[$0] }.forEach { himno in
            favoritesManager.removeFromFavorites(id: himno.id, himnarioVersion: himno.himnarioVersion)
        }
    }
}

#Preview {
    FavoriteView()
        .environmentObject(FavoritesManager())
        .environmentObject(AudioPlaybackState())
}

