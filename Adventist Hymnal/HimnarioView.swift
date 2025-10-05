//
//  HimnarioView.swift
//  Adventist Hymnal SwiftUI
//
//  Created by Jose Pimentel on 2/26/25.
//

import SwiftUI

struct HimnarioView: View {
    var himnos: [Himnario]
    @State private var searchText = ""
    @State private var isSearching = false
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var playbackState: AudioPlaybackState
    let himnoSearch: HimnarioSearch = HimnarioSearch()
    @State private var himnoSearchResult: [Himnario] = []
    
    var body: some View {
        VStack {
            
            SearchBar(text: $searchText, onCommit: {
                himnoSearchResult = himnoSearch.search(query: searchText, himnos: himnos)
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
                        Text("No hymns found")
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
                    }
                } else {
                    // Not searching: show all himnos
                    ForEach(himnos) { himno in
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
                }
            }
            .padding(2)
        }
        .navigationTitle("SDA Hymnal")
    }
}

#Preview {
    let favoritesManager = FavoritesManager()
    let playbackState = AudioPlaybackState()
    let adventistHymnal: [Himnario] = Bundle.main.decode("adventistHymnal.json")
    HimnarioView(himnos: adventistHymnal)
        .environmentObject(favoritesManager)
        .environmentObject(playbackState)
}
