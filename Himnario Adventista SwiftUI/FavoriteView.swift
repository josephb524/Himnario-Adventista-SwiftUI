import SwiftUI

struct FavoriteView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @State private var searchText = ""
    @State private var isSearching = false
    // Assuming HimnarioSearch is defined elsewhere in your project.
    let himnoSearch: HimnarioSearch = HimnarioSearch()
    @State private var himnoSearchResult: [Himnario] = []
    
    var body: some View {
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
                ForEach(isSearching && !himnoSearchResult.isEmpty ? himnoSearchResult : favoritesManager.favoriteHimnos) { himno in
                    NavigationLink(destination: HimnoDetailView(himno: himno, himnos: [])) {
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
        .navigationTitle("Favorites (\(favoritesManager.favoriteHimnos.count))")
    }
}

#Preview {
    let sampleHimnos: [Himnario] = Bundle.main.decode("himnarioNuevo.json")
    let favoritesManager = FavoritesManager()
    favoritesManager.favoriteHimnos = sampleHimnos // Use sample data for preview.
    
    NavigationView {
        FavoriteView()
    }
    .environmentObject(favoritesManager)
}