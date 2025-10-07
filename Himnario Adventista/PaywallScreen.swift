//
//  PaywallScreen.swift
//  Himnario Adventista SwiftUI
//

import SwiftUI

struct PaywallScreen: View {
    @StateObject private var subManager = SubscriptionManager.shared
    @Binding var isPresented: Bool
    @State private var showingError = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Desbloquea Funciones Premium de Playlists")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "music.note.list", text: "Crea listas de reproducción personalizadas ilimitadas")
                FeatureRow(icon: "plus.circle", text: "Añade himnos a tus colecciones personales")
                FeatureRow(icon: "play.circle", text: "Reproducción continua de listas")
                FeatureRow(icon: "shuffle", text: "Modos de aleatorio y repetición")
                FeatureRow(icon: "heart", text: "Guarda y organiza tus himnos favoritos")
            }
            .padding(.horizontal, 8)
            .padding(.vertical)
            
            VStack(spacing: 8) {
                if subManager.isLoading && subManager.subscriptionProduct == nil {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Cargando precios...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(subManager.subscriptionPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("por \(subManager.subscriptionPeriod)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                Task {
                    do {
                        try await subManager.purchase()
                        if subManager.isSubscribed {
                            isPresented = false
                        }
                    } catch SubscriptionError.userCancelled {
                        return
                    } catch {
                        showingError = true
                    }
                }
            }) {
                HStack {
                    if subManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Procesando...")
                    } else {
                        Image(systemName: "crown.fill")
                        Text("COMENZAR AHORA")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(subManager.isLoading || subManager.subscriptionProduct == nil)
            .opacity(subManager.isLoading || subManager.subscriptionProduct == nil ? 0.6 : 1.0)
            
            Text("El pago se cargará a tu cuenta de iTunes al confirmar la compra. La suscripción se renueva automáticamente a menos que se desactive la renovación automática al menos 24 horas antes del final del período actual. La cuenta se cargará por la renovación dentro de las 24 horas previas al final del período actual.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            HStack {
                Button("Política de Privacidad") {
                    showPrivacyPolicy = true
                }
                Spacer()
                Button("Términos de Uso") {
                    showTermsOfUse = true
                }
            }
            .font(.caption)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Después") {
                    isPresented = false
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Restaurar") {
                    Task {
                        await subManager.restore()
                        if subManager.isSubscribed {
                            isPresented = false
                        } else if let _ = subManager.errorMessage {
                            showingError = true
                        }
                    }
                }
                .disabled(subManager.isLoading)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(subManager.errorMessage ?? "Ocurrió un error inesperado. Por favor, inténtalo de nuevo.")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationView { PrivacyPolicyView() }
        }
        .sheet(isPresented: $showTermsOfUse) {
            NavigationView { TermsView() }
        }
        .onAppear {
            if subManager.subscriptionProduct == nil && !subManager.isLoading {
                Task { await subManager.loadProducts() }
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .foregroundColor(.blue)
            Text(text)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Placeholder views to avoid missing references during integration
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy placeholder")
                .padding()
        }
        .navigationTitle("Política de Privacidad")
    }
}

struct TermsView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Use placeholder")
                .padding()
        }
        .navigationTitle("Términos de Uso")
    }
}


