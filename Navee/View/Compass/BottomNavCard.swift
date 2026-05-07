//
//  BottomNavCard.swift
//  Navee
//

import SwiftUI

// MARK: - BottomNavCard

struct BottomNavCard: View {
    let nav: NavState
    let finalArrived: Bool
    let currentTarget: Location?
    let finalDestination: Location?
    let distanceToFinal: Double
    let currentStep: Int      // index step yang sedang dituju — untuk posisi dot
    let pointsPassed: Int     // jumlah yang sudah dilewati — untuk label teks
    let totalSteps: Int
    var onEndNavigation: () -> Void
    var onExit: () -> Void

    private var statusColor: Color {
        if nav.hasArrived { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return nav.isOnTrack ? Color(red: 0.20, green: 0.78, blue: 0.35) : .white
    }

    private func formatDistance(_ d: Double) -> String {
        guard d > 0 else { return "—" }
        return d < 1000
            ? "\(Int(d)) m"
            : String(format: "%.1f km", d / 1000)
    }

    private var isSinglePoint: Bool { totalSteps <= 1 }

    private var isCheckpointSameAsFinal: Bool {
        currentTarget?.id == finalDestination?.id
    }

    private var showCheckpointRow: Bool {
        !isSinglePoint && !isCheckpointSameAsFinal
    }

    var body: some View {
        navContent
            .background(
                Color(red: 0.11, green: 0.11, blue: 0.12)
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: 28,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 28,
                        style: .continuous
                    ))
                    .ignoresSafeArea(edges: .bottom)
            )
    }

    // MARK: - Nav Content

    private var navContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            if showCheckpointRow {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(statusColor)

                    Text("Heading to \(currentTarget?.name ?? "—")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)

                    Spacer()

                    Text(formatDistance(nav.distance))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(statusColor)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.35), value: nav.distance)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
            }

            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(isSinglePoint ? "navigating to" : "destination")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .textCase(.uppercase)
                        .kerning(0.6)

                    Text(finalDestination?.name ?? currentTarget?.name ?? "—")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if showCheckpointRow {
                        Text("total")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.25))
                            .textCase(.uppercase)
                            .kerning(0.4)
                    }
                    Text(formatDistance(showCheckpointRow ? distanceToFinal : nav.distance))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.35), value: distanceToFinal)
                }
            }
            .padding(.horizontal, 20)

            if totalSteps > 1 {
                MRTProgressLine(
                    currentStep:  currentStep,   // dot ikut currentStep asli, tidak loncat duluan
                    pointsPassed: pointsPassed,  // label teks pakai pointsPassed
                    totalSteps:   totalSteps,
                    activeColor:  statusColor
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            EndNavButton(label: "End Navigate", action: onEndNavigation)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - End Nav Button

struct EndNavButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 50, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 50, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )

                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.33, blue: 0.30))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(ModalButtonStyle())
    }
}

// MARK: - Button Styles

struct ModalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - MRT Progress Line

private struct MRTProgressLine: View {
    let currentStep: Int    // index step yang sedang dituju — untuk posisi dot
    let pointsPassed: Int   // jumlah yang sudah dilewati — untuk label teks
    let totalSteps: Int
    let activeColor: Color

    private let green     = Color(red: 0.20, green: 0.78, blue: 0.35)
    private let maxVisible = 5

    private var visibleRange: Range<Int> {
        guard totalSteps > maxVisible else { return 0..<totalSteps }
        let half  = maxVisible / 2
        let start = max(0, min(currentStep - half, totalSteps - maxVisible))
        return start..<(start + maxVisible)
    }

    private var showLeadingEllipsis:  Bool { visibleRange.lowerBound > 0 }
    private var showTrailingEllipsis: Bool { visibleRange.upperBound < totalSteps }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                if showLeadingEllipsis { ellipsis }

                ForEach(Array(visibleRange.enumerated()), id: \.offset) { idx, step in
                    let isCurrent = step == currentStep
                    let isLast    = step == totalSteps - 1

                    if idx > 0 || showLeadingEllipsis {
                        connectorLine(highlighted: step < currentStep)
                    }

                    ZStack {
                        if isCurrent {
                            // Dot yang sedang dituju:
                            // kuning = checkpoint biasa, hijau = titik terakhir (final destination)
                            let dotColor = isLast ? green : activeColor
                            Circle()
                                .fill(dotColor.opacity(0.2))
                                .frame(width: 14, height: 14)
                            Circle()
                                .fill(dotColor)
                                .frame(width: 7, height: 7)
                        } else {
                            // Sudah lewat atau belum sampai — warna normal redup
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(width: 14, height: 14)
                }

                if showTrailingEllipsis {
                    connectorLine(highlighted: false)
                    ellipsis
                }
            }
            .fixedSize()

            Spacer(minLength: 8)

            Text("\(pointsPassed) / \(totalSteps) points passed")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.28))
                .fixedSize()
        }
        .frame(height: 14)
    }

    private func connectorLine(highlighted: Bool) -> some View {
        Rectangle()
            .fill(highlighted ? Color.white.opacity(0.35) : Color.white.opacity(0.12))
            .frame(width: 10, height: 1.5)
    }

    private var ellipsis: some View {
        Text("···")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white.opacity(0.2))
            .frame(width: 14)
    }
}
