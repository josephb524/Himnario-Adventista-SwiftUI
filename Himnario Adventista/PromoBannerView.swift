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
                HStack(spacing: 16) {
                    // App icon image
                    AsyncImage(url: URL(string: banner.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        case .failure:
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "app.fill")
                                        .foregroundColor(.gray)
                                )
                        case .empty:
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 64, height: 64)
                                .overlay(ProgressView())
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(banner.title)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(banner.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Dismiss button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isDismissed = true
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                )
                .padding(.horizontal)
                .padding(.top, 6)
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .onAppear {
                // Reset dismissal each time this view appears (e.g. navigating back to the page)
                isDismissed = false
            }
        }
    }
}
