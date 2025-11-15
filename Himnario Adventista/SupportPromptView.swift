//
//  SupportPromptView.swift
//  Himnario Adventista SwiftUI
//
//  Periodic prompt asking users to support the app

import SwiftUI

struct SupportPromptView: View {
    @Binding var isPresented: Bool
    let onSupportAction: () -> Void
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
                // Heart icon and title section
                VStack(spacing: 16) {
                    // Heart icon with gradient
                    ZStack {
                        Circle()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.8), Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("¿Disfrutas de nuestro himnario?")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Tu apoyo voluntario nos ayuda a mantener esta aplicación gratuita y a compartir estos himnos con más personas.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                .padding(.top, 8)
                
                // Heart icons display
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "heart.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    // Primary action - Support app
                    Button(action: {
                        supportApp()
                    }) {
                        HStack {
                            Image(systemName: "heart.circle.fill")
                                .font(.body)
                            Text("Apoyar la App")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
    
    private func supportApp() {
        onSupportAction()
        SupportPromptManager.shared.userOpenedSupport()
        isPresented = false
    }
    
    private func dismissPrompt() {
        // User tapped "Más tarde" - show again after 3 app launches
        SupportPromptManager.shared.userDismissedSupport(type: .masTarde)
        onDismiss()
        isPresented = false
    }
    
    private func dismissPermanently() {
        // User tapped "No, gracias" - show again after 15 app launches
        SupportPromptManager.shared.userDismissedSupport(type: .noThanks)
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
        
        SupportPromptView(
            isPresented: $isPresented,
            onSupportAction: {},
            onDismiss: {}
        )
    }
}

