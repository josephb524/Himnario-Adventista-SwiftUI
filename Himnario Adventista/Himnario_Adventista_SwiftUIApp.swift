//
//  Himnario_Adventista_SwiftUIApp.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 2/25/25.
//

import SwiftUI

@main
struct Himnario_Adventista_SwiftUIApp: App {
    
    init() {
        PromoBannerManager.shared.fetchBanners()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
