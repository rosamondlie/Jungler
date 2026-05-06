//
//  ArrivalFlashOverlay.swift
//  Navee
//
//  Created by neena on 06/05/26.
//

import SwiftUI

struct ArrivalFlashOverlay: View {
    let kind: ArrivalKind
    let opacity: Double

    var body: some View {
        // Hanya untuk .checkpoint — .final sudah ditangani BottomNavCard
        ZStack {
            Color.black.opacity(opacity * 0.35)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundStyle(Color(red: 0.20, green: 0.78, blue: 0.35))
                    .symbolRenderingMode(.hierarchical)

                Text("Checkpoint")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)

                Text("Moving to the next point")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
            .background(glassBackground)
            .padding(.horizontal, 24)
            .scaleEffect(0.88 + 0.12 * opacity)
            .opacity(opacity)
        }
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
    }
}
