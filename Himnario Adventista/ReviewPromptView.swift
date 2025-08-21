//
//  ReviewPromptView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/20/25.
//

import SwiftUI
import StoreKit

struct ReviewPromptView: View {
    @Binding var isPresented: Bool
    @State private var showingAppStore = false
    let onReviewAction: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPrompt()
                }
            
            // Main prompt card
            VStack(spacing: 24) {
                // App icon and title section
                VStack(spacing: 16) {
                    // App icon placeholder (you can replace with actual app icon)
                    RoundedRectangle(cornerRadius: 16)
                        .frame(width: 80, height: 80)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    
                    VStack(spacing: 8) {
                        Text("¿Te gusta nuestra app?")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Tu opinión es muy importante para nosotros y nos ayuda a mejorar la experiencia para todos.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                .padding(.top, 8)
                
                // Star rating display
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    // Primary action - Rate app
                    Button(action: {
                        rateApp()
                    }) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .font(.body)
                            Text("Calificar App")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Secondary actions
                    HStack(spacing: 12) {
                        // Maybe later button
                        Button("Más tarde") {
                            dismissPrompt()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .buttonStyle(PlainButtonStyle())
                        
                        // No thanks button
                        Button("No, gracias") {
                            dismissPermanently()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .foregroundColor(.secondary)
                        .cornerRadius(10)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
        .opacity(isPresented ? 1 : 0)
        .scaleEffect(isPresented ? 1 : 0.8)
    }
    
    private func rateApp() {
        onReviewAction()
        
        // Try to open App Store for rating
        if let writeReviewURL = URL(string: "https://apps.apple.com/app/id1525895857?action=write-review") {
            UIApplication.shared.open(writeReviewURL)
        } else {
            // Fallback to native review prompt
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
        
        isPresented = false
    }
    
    private func dismissPrompt() {
        onDismiss()
        isPresented = false
    }
    
    private func dismissPermanently() {
        ReviewManager.shared.userDismissedReview()
        onDismiss()
        isPresented = false
    }
}

// MARK: - Preview
#Preview {
    @State var isPresented = true
    
    return ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        ReviewPromptView(
            isPresented: $isPresented,
            onReviewAction: {
                print("User chose to review")
            },
            onDismiss: {
                print("User dismissed prompt")
            }
        )
    }
} 