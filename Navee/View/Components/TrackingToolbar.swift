//
//  TrackingToolbar.swift
//  Navee
//

import SwiftUI

struct TrackingToolbar: View {
    let pinCount:    Int
    let onShowMarks: () -> Void
    let onAddMark:   () -> Void
    let onEndTrek:   () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                endTrekButton
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()

            HStack(spacing: 12) {
                savedMarksButton
                addMarkButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
    }

    // MARK: - End Trek

    private var endTrekButton: some View {
        Button(action: onEndTrek) {
            HStack(spacing: 6) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("End Trek")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                ZStack {
                    // Base fill
                    Capsule()
                        .fill(Color.red)
                    // Top highlight — simulasi cahaya dari atas
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.28), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    // Edge border
                    Capsule()
                        .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                }
            }
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Saved Marks

    private var savedMarksButton: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onShowMarks) {
                ZStack {
                    // Base glass
                    Circle()
                        .fill(.ultraThinMaterial)
                    // Top highlight
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    // Edge border
                    Circle()
                        .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)

                    Image(systemName: "flag.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(width: 64, height: 64)
                // Shadow
                .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)

            if pinCount > 0 {
                PinCountBadge(count: pinCount)
                    .offset(x: 6, y: -6)
            }
        }
    }

    // MARK: - Add Mark

    private var addMarkButton: some View {
        Button(action: onAddMark) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                Text("Add Mark")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(Color(red: 0.20, green: 0.12, blue: 0.00))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background {
                ZStack {
                    // Base amber
                    Capsule()
                        .fill(Color(red: 1.0, green: 0.80, blue: 0.15))
                    // Top highlight
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    // Edge border
                    Capsule()
                        .strokeBorder(.white.opacity(0.4), lineWidth: 0.5)
                }
            }
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PinCountBadge

private struct PinCountBadge: View {
    let count: Int

    var body: some View {
        Text("\(min(count, 99))")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(minWidth: 20, minHeight: 20)
            .padding(.horizontal, 4)
            .background(
                Capsule()
                    .fill(Color(red: 0.18, green: 0.78, blue: 0.35))
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.1, green: 0.15, blue: 0.1).ignoresSafeArea()
        TrackingToolbar(
            pinCount:    3,
            onShowMarks: {},
            onAddMark:   {},
            onEndTrek:   {}
        )
    }
}
