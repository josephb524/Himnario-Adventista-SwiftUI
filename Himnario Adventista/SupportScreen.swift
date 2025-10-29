//
//  SupportScreen.swift
//  Himnario Adventista SwiftUI
//
//  Voluntary support/giving screen for users to support the app

import SwiftUI
import StoreKit

struct SupportScreen: View {
    @StateObject private var subManager = SubscriptionManager.shared
    @Binding var isPresented: Bool
    @State private var showingError = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    @State private var selectedTier: SupportTier? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with heart emoji
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text("Apoyo")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                // Message
                Text("Con tu ayuda podemos hacer más juntos. ¡Ayúdanos a compartir estos himnos con más personas!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                
                // Terms and Privacy links
                HStack(spacing: 0) {
                    Button("Términos de Servicio") {
                        showTermsOfUse = true
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                    
                    Text(" y ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Política de Privacidad") {
                        showPrivacyPolicy = true
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
                .padding(.bottom, 8)
                
                // Support tiers
                VStack(spacing: 12) {
                    if subManager.isLoading && subManager.subscriptionProducts.isEmpty {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Cargando opciones de apoyo...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Support tiers - dynamically get prices from products
                        ForEach([SupportTier.basic, SupportTier.supporter, SupportTier.patron, SupportTier.benefactor], id: \.rawValue) { tier in
                            if let product = subManager.getProduct(for: tier.rawValue) {
                                SupportTierCard(
                                    title: tier.title,
                                    price: "\(product.displayPrice)/mes",
                                    description: tier.description,
                                    isSelected: selectedTier == tier,
                                    onTap: { selectedTier = tier }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Subscribe button
                Button(action: {
                    if let tier = selectedTier {
                        Task {
                            do {
                                try await subManager.purchase(productID: tier.rawValue)
                            } catch SubscriptionError.userCancelled {
                                return
                            } catch {
                                showingError = true
                            }
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        if subManager.isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Procesando...")
                            }
                        } else {
                            Text("Suscribir")
                                .font(.headline)
                            if let tier = selectedTier,
                               let product = subManager.getProduct(for: tier.rawValue) {
                                Text(tier.autoRenewText(price: product.displayPrice))
                                    .font(.caption)
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        selectedTier == nil || subManager.isLoading || subManager.subscriptionProducts.isEmpty
                            ? Color.gray.opacity(0.5)
                            : Color.blue
                    )
                    .cornerRadius(12)
                }
                .disabled(selectedTier == nil || subManager.isLoading || subManager.subscriptionProducts.isEmpty)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Restore button
                Button("Restaurar Suscripción") {
                    Task {
                        await subManager.restore()
                        if subManager.isSubscribed {
                            isPresented = false
                        } else if let _ = subManager.errorMessage {
                            showingError = true
                        }
                    }
                }
                .font(.body)
                .foregroundColor(.blue)
                .disabled(subManager.isLoading)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(subManager.errorMessage ?? "Ocurrió un error inesperado. Por favor, inténtalo de nuevo.")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationView {
                PrivacyPolicyView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cerrar") {
                                showPrivacyPolicy = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showTermsOfUse) {
            NavigationView {
                TermsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cerrar") {
                                showTermsOfUse = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            if subManager.subscriptionProducts.isEmpty && !subManager.isLoading {
                Task { await subManager.loadProducts() }
            }
        }
    }
}

// Support tier card component
private struct SupportTierCard: View {
    let title: String
    let price: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(price)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Support tier enum
enum SupportTier: String, Equatable {
    case basic = "com.JosePimentel.HimnarioViejoYNuevo.Basico"
    case supporter = "com.JosePimentel.HimnarioViejoYNuevo.Seguidor"
    case patron = "com.JosePimentel.HimnarioViejoYNuevo.Patrocinador"
    case benefactor = "com.JosePimentel.HimnarioViejoYNuevo.Benefactor"
    
    var title: String {
        switch self {
        case .basic:
            return "Apoyo Básico"
        case .supporter:
            return "Seguidor"
        case .patron:
            return "Patrocinador"
        case .benefactor:
            return "Benefactor"
        }
    }
    
    var description: String {
        switch self {
        case .basic:
            return "Ayuda a mantener la aplicación activa y funcionando."
        case .supporter:
            return "Apoya el desarrollo continuo de nuevas funciones."
        case .patron:
            return "Contribuye significativamente al proyecto."
        case .benefactor:
            return "Sé un gran benefactor y ayuda a mantener este himnario gratuito para todos."
        }
    }
    
    func autoRenewText(price: String) -> String {
        return "El plan se renueva automáticamente por \(price) hasta que se cancele."
    }
}

// Privacy Policy and Terms views
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Política de Privacidad")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                Text("Última actualización: \(Date().formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                Group {
                    Text("1. Información que Recopilamos")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Recopilamos información mínima necesaria para proporcionar nuestros servicios:")
                        .padding(.top, 4)
                    
                    Text("• Información de suscripción para procesar pagos\n• Preferencias de usuario para personalizar la experiencia\n• Datos de uso anónimos para mejorar la aplicación")
                        .padding(.top, 4)
                    
                    Text("2. Uso de la Información")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Utilizamos la información recopilada para:")
                        .padding(.top, 4)
                    
                    Text("• Procesar suscripciones y pagos\n• Mejorar la funcionalidad de la aplicación\n• Proporcionar soporte al cliente\n• Cumplir con obligaciones legales")
                        .padding(.top, 4)
                    
                    Text("3. Compartir Información")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("No vendemos, alquilamos ni compartimos su información personal con terceros, excepto cuando sea necesario para procesar pagos a través de Apple.")
                        .padding(.top, 4)
                    
                    Text("4. Seguridad")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Implementamos medidas de seguridad apropiadas para proteger su información personal contra acceso no autorizado, alteración, divulgación o destrucción.")
                        .padding(.top, 4)
                    
                    Text("5. Sus Derechos")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Usted tiene derecho a acceder, corregir o eliminar su información personal. Puede contactarnos en cualquier momento para ejercer estos derechos.")
                        .padding(.top, 4)
                    
                    Text("6. Contacto")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Si tiene preguntas sobre esta Política de Privacidad, puede contactarnos a través de la App Store o por correo electrónico: eltercerelias3@hotmail.com")
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Política de Privacidad")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Términos de Uso")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                Text("Última actualización: \(Date().formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                Group {
                    Text("1. Aceptación de los Términos")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Al utilizar la aplicación Himnario Adventista, usted acepta estar sujeto a estos términos y condiciones de uso.")
                        .padding(.top, 4)
                    
                    Text("2. Descripción del Servicio")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Himnario Adventista es una aplicación móvil que proporciona acceso a himnos adventistas y listas de reproducción personalizadas. El apoyo voluntario ayuda a mantener y mejorar la aplicación.")
                        .padding(.top, 4)
                    
                    Text("3. Apoyo Voluntario y Pagos")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("• El apoyo a la aplicación es completamente voluntario\n• Los pagos se procesan a través de la App Store de Apple\n• Puede cancelar su apoyo en cualquier momento desde la configuración de su dispositivo\n• No ofrecemos reembolsos por suscripciones ya utilizadas")
                        .padding(.top, 4)
                    
                    Text("4. Uso Aceptable")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Usted se compromete a utilizar la aplicación de manera responsable y no debe:")
                        .padding(.top, 4)
                    
                    Text("• Usar la aplicación para fines ilegales o no autorizados\n• Intentar modificar, descompilar o hacer ingeniería inversa de la aplicación")
                        .padding(.top, 4)
                    
                    Text("5. Propiedad Intelectual")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Todos los himnos y contenido musical incluido en la aplicación son propiedad de sus respectivos dueños. El uso está limitado al disfrute personal y no comercial.")
                        .padding(.top, 4)
                    
                    Text("6. Limitación de Responsabilidad")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("La aplicación se proporciona 'tal como está'. No garantizamos que la aplicación esté libre de errores o interrupciones, y no seremos responsables por daños directos o indirectos.")
                        .padding(.top, 4)
                    
                    Text("7. Modificaciones")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios entrarán en vigor inmediatamente después de su publicación en la aplicación.")
                        .padding(.top, 4)
                    
                    Text("8. Terminación")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Podemos suspender o terminar su acceso a la aplicación en cualquier momento si viola estos términos de uso.")
                        .padding(.top, 4)
                    
                    Text("9. Contacto")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Para preguntas sobre estos términos, puede contactarnos a través de la App Store o por correo electrónico: eltercerelias3@hotmail.com")
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Términos de Uso")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SupportScreen(isPresented: .constant(true))
    }
}

