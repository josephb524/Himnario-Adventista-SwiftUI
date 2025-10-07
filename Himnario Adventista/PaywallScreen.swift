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
                    
                    Text("Himnario Adventista es una aplicación móvil que proporciona acceso a himnos adventistas, listas de reproducción personalizadas y funcionalidades premium mediante suscripción.")
                        .padding(.top, 4)
                    
                    Text("3. Suscripciones y Pagos")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("• Las suscripciones se facturan automáticamente\n• Los pagos se procesan a través de la App Store de Apple\n• Puede cancelar su suscripción en cualquier momento desde la configuración de su dispositivo\n• No ofrecemos reembolsos por suscripciones ya utilizadas")
                        .padding(.top, 4)
                    
                    Text("4. Uso Aceptable")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Usted se compromete a utilizar la aplicación de manera responsable y no debe:")
                        .padding(.top, 4)
                    
                    Text("• Intentar acceder a funciones premium sin suscripción válida\n• Usar la aplicación para fines ilegales o no autorizados\n• Intentar modificar, descompilar o hacer ingeniería inversa de la aplicación")
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


