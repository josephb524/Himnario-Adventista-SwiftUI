//
//  PlaylistService.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 8/22/21.
//

import Foundation

final class PlaylistService {
    let hostService = AudiusHostService()
    
    func findPlaylistURL(
        coritoFavorito: String,
        isVoice: Bool,
        indexCorito: Int,
        completion: @escaping (String?) -> Void
    ) {
        let (playlist1, playlist2, playlist3, playlist4) = makePlaylistIds(coritoFavorito: coritoFavorito, isVoice: isVoice)
        hostService.fetchAudiusHost { resolvedHost in
            let host = resolvedHost ?? "https://audius-discovery-3.altego.net"
            let (chosenPid, _) = self.selectPlaylist(
                indexCorito: indexCorito,
                playlist1: playlist1,
                playlist2: playlist2,
                playlist3: playlist3,
                playlist4: playlist4
            )
            let finalURL = "\(host)/v1/playlists/\(chosenPid)/tracks?app_name=CoritosAdventistas"
            completion(finalURL)
        }
    }
    
    private func makePlaylistIds(coritoFavorito: String, isVoice: Bool) -> (String, String, String, String) {
        var p1 = ""
        var p2 = ""
        var p3 = ""
        var p4 = ""
        
        // Now we only have the 1985 hymnal version
        if isVoice {
            p1 = "ezPGw"
            p2 = "L5oP1"
            p3 = "DyYrZ"
            p4 = "n1mw3"
        } else {
            p1 = "oEgmv"
            p2 = "ZZk3J"
            p3 = "qE7ao"
            p4 = "5QBMx"
        }
        
        return (p1, p2, p3, p4)
    }
    
    private func selectPlaylist(
        indexCorito: Int,
        playlist1: String,
        playlist2: String,
        playlist3: String,
        playlist4: String
    ) -> (pid: String, finalIndex: Int) {
        switch indexCorito {
        case 0..<200:
            return (playlist1, indexCorito)
        case 200..<400:
            return (playlist2, indexCorito - 200)
        case 400..<600:
            return (playlist3, indexCorito - 400)
        default:
            return (playlist4, indexCorito - 600)
        }
    }
}
