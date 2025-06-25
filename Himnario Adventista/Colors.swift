//
//  Colors.swift
//  Concordancia Biblica
//
//  Created by Jose Pimentel on 12/1/24.
//

import SwiftUI

struct Colors {
    
    static var shared = Colors()
    let navigationBarGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.blue,
            Color.purple,
            Color.cyan
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
}
