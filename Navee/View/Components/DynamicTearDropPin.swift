//
//  DynamicTearDropPin.swift
//  Navee
//

import SwiftUI

// MARK: - DynamicTearDropPin

struct DynamicTearDropPin: View {
    let location:   Location
    let isSelected: Bool
    let onTap:      () -> Void

    private var iconName: String               { PinIconHelper.iconName(for: location.emoji) }
    private var colors: (top: Color, bottom: Color) { PinIconHelper.colors(for: location.emoji) }

    var body: some View {
        PinBody(iconName: iconName, colors: colors, isSelected: isSelected)
            .onTapGesture { onTap() }
    }
}

// MARK: - PinBody

private struct PinBody: View {
    let iconName:   String
    let colors:     (top: Color, bottom: Color)
    let isSelected: Bool

    // Ukuran pin normal
    private let baseSize:     CGFloat = 36
    private let baseTailW:    CGFloat = 12
    private let baseTailH:    CGFloat = 10
    private let baseIconSize: CGFloat = 15

    // Ukuran pin selected — lebih besar supaya kerasa seperti Apple Maps
    private let selectedSize:     CGFloat = 48
    private let selectedTailW:    CGFloat = 16
    private let selectedTailH:    CGFloat = 13
    private let selectedIconSize: CGFloat = 20

    private var circleSize: CGFloat  { isSelected ? selectedSize     : baseSize }
    private var tailW:      CGFloat  { isSelected ? selectedTailW    : baseTailW }
    private var tailH:      CGFloat  { isSelected ? selectedTailH    : baseTailH }
    private var iconSize:   CGFloat  { isSelected ? selectedIconSize : baseIconSize }

    private let spring: Animation = .spring(response: 0.3, dampingFraction: 0.6)

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Shadow supaya pin "terangkat" saat selected
                if isSelected {
                    Circle()
                        .fill(Color.black.opacity(0.25))
                        .frame(width: circleSize + 4, height: circleSize + 4)
                        .blur(radius: 6)
                        .offset(y: 3)
                }

                Circle()
                    .fill(LinearGradient(
                        colors: [colors.top, colors.bottom],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: circleSize, height: circleSize)
                    // Stroke tipis saat selected, seperti Apple Maps
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isSelected ? 0.6 : 0), lineWidth: 2)
                    )

                Image(systemName: iconName)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(.white)
            }

            PinTail()
                .fill(colors.bottom)
                .frame(width: tailW, height: tailH)
                .offset(y: -1)
        }
        // Animasi ukuran — pakai animatable size bukan scaleEffect
        // supaya anchor point (bawah/ujung tail) tidak bergeser
        .animation(spring, value: isSelected)
    }
}

// MARK: - PinTail Shape

private struct PinTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
