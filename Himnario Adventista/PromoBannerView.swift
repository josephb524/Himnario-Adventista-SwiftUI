//
//  PromoBannerView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/20/26.
//

import SwiftUI

struct PromoBannerView: View {
    @ObservedObject var manager = PromoBannerManager.shared
    @State private var isDismissed = false
    
    var body: some View {
        if let banner = manager.banners.first, !isDismissed {
            Button(action: {
                if let url = URL(string: banner.destinationURL) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 12) {
                    // App icon image
                    AsyncImage(url: URL(string: banner.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "app.fill")
                                        .foregroundColor(.gray)
                                )
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 50, height: 50)
                                .overlay(ProgressView())
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        Text(banner.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(banner.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Dismiss button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isDismissed = true
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal)
                .padding(.top, 4)
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}
