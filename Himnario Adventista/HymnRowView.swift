//
//  HymnRowView.swift
//  Himnario Adventista SwiftUI
//
//  Created by Jose Pimentel on 3/21/25.
//

import SwiftUI

struct HymnRowView: View {
    let himno: Himnario
    
    var body: some View {
        HStack(spacing: 16) {
            // Left accent with gradient
            LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 4)
            .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(himno.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Version badge
                    Text(himno.himnarioVersion == "Nuevo" ? "N" : "A")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(himno.himnarioVersion == "Nuevo" ? Color.blue : Color.orange)
                        )
                }
                
                Text(himno.himno)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        HymnRowView(himno: Himnario(id: 1, title: "Santo, Santo, Santo", himno: "Santo, Santo, Santo, Señor omnipotente. Siempre el labio mío loores te dará.", isFavorito: false, himnarioVersion: "Nuevo"))
        HymnRowView(himno: Himnario(id: 2, title: "Cuán Grande Es Él", himno: "Señor mi Dios, al contemplar los cielos, el firmamento y las estrellas mil.", isFavorito: false, himnarioVersion: "Antiguo"))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 