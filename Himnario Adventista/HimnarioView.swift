//
//  HimnarioNuevo.swift
//  Himnario Adventista SwiftUI
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
        VStack(spacing: 0) {
            // Search section
            VStack(spacing: 12) {
                SearchBar(text: $searchText, onCommit: {
                    himnoSearchResult = himnoSearch.search(query: searchText, himnos: himnos)
                    isSearching = !searchText.isEmpty
                }, onClear: {
                    searchText = ""
                    isSearching = false
                    himnoSearchResult = []
                })
                
                if isSearching && !searchText.isEmpty {
                    HStack {
                        Text("Resultados para: \"\(searchText)\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(himnoSearchResult.count) himnos")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            // Hymn list
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isSearching {
                        if himnoSearchResult.isEmpty {
                            // Empty search state
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                Text("No se encontraron himnos")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Intenta con otras palabras clave")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
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
                            }
                        }
                    } else {
                        ForEach(himnos) { himno in
                            NavigationLink(destination: HimnoDetailView(himno: himno)
                                .environmentObject(favoritesManager)
                                .environmentObject(playbackState)) {
                                HymnRowView(himno: himno)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Space for tab bar
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    let favoritesManager = FavoritesManager()
    let playbackState = AudioPlaybackState()
    let himnarioNuevo: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
    HimnarioView(himnos: himnarioNuevo)
        .environmentObject(favoritesManager)
        .environmentObject(playbackState)
}
