//
//  AudioPlaybackState.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/2/25.
//

import Foundation

class AudioPlaybackState: ObservableObject {
    @Published var himnoTitle: String = ""
    @Published var trackTime: String = "00:00"
    @Published var progress: Float = 0.0
    @Published var isPlaying: Bool = false
    @Published var isVocal: Bool = true
    @Published var numericId: Int = 0
}
