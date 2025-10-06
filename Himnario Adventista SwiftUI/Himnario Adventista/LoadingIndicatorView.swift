//
//  LoadingIndicatorView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/16/25.
//


import SwiftUI

struct LoadingIndicatorView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.6)
            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .foregroundColor(.blue)
            .frame(width: 40, height: 40)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct LoadingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingIndicatorView()
    }
}
