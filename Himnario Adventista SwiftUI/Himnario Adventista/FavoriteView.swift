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
            VStack {
                SearchBar(text: $searchText, onCommit: {
                    himnoSearchResult = himnoSearch.search(query: searchText, himnos: favoritesManager.favoriteHimnos)
                    isSearching = !searchText.isEmpty
                }, onClear: {
                    searchText = ""
                    isSearching = false
                    himnoSearchResult = []
                })
                .padding(.horizontal)
                
                List {
                    // If the user is searching
                    if isSearching {
                        // If the search results are empty, show a placeholder message
                        if himnoSearchResult.isEmpty {
                            Text("No results found.")
                                .foregroundColor(.gray)
                        } else {
                            // Otherwise, show the search results
                            ForEach(himnoSearchResult) { himno in
                                NavigationLink(destination: HimnoDetailView(himno: himno)
                                    .environmentObject(favoritesManager)
                                    .environmentObject(playbackState)) {
                                        VStack(alignment: .leading) {
                                            Text(himno.title)
                                                .font(.headline)
                                            Text(himno.himno)
                                                .lineLimit(2)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                            }
                            .onDelete(perform: delete)
                        }
                    } else {
                        // Not searching: show all favorites
                        if favoritesManager.favoriteHimnos.isEmpty {
                            VStack {
                                Image(systemName: "star")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No hay favoritos aún")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Agrega himnos a favoritos para verlos aquí")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        } else {
                            ForEach(favoritesManager.favoriteHimnos) { himno in
                                NavigationLink(destination: HimnoDetailView(himno: himno)
                                    .environmentObject(favoritesManager)
                                    .environmentObject(playbackState)) {
                                        VStack(alignment: .leading) {
                                            Text(himno.title)
                                                .font(.headline)
                                            Text(himno.himno)
                                                .lineLimit(2)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
                .padding(2)
            }
            .navigationTitle("Favoritos")
            .toolbarBackground(Colors.shared.getNavigationBarGradient(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func delete(at offsets: IndexSet) {
        offsets.map { favoritesManager.favoriteHimnos[$0] }.forEach { himno in
            favoritesManager.removeFromFavorites(id: himno.numericId, himnarioVersion: himno.himnarioVersion)
        }
    }
}

//#Preview {
//    let sampleHimnos: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
//    let favoritesManager = FavoritesManager()
//     @StateObject private var favoritesManager = FavoritesManager()
//    NavigationView {
//        FavoriteView()
//    }
//    .environmentObject(favoritesManager)
//}

