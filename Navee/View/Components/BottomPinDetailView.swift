//
//  BottomPinDetailView.swift
//  Navee
//

import SwiftUI
import CoreLocation

struct BottomPinDetailView: View {
    let location:          Location
    var userLocation:      CLLocation?
    var isWatchNavigating: Bool = false
    var onNavigate:        () -> Void
    var onEdit:            () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: Header
            HStack(spacing: 14) {
                PinIconBox(emoji: location.emoji, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    LocationMetaRow(location: location, userLocation: userLocation)

                    Text(location.timestamp.relativeFormatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // MARK: Navigate Button
            Button(action: onNavigate) {
                HStack(spacing: 8) {
                    Image(systemName: isWatchNavigating ? "applewatch" : "location.fill")
                    Text(isWatchNavigating ? "Navigating on Watch" : "Navigate")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isWatchNavigating ? .white.opacity(0.4) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    isWatchNavigating
                        ? Color.white.opacity(0.08)
                        : Color.blue
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isWatchNavigating ? Color.white.opacity(0.12) : Color.clear,
                            lineWidth: 0.5
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isWatchNavigating)

            // MARK: Edit
            Button(action: onEdit) {
                Label("Edit Point", systemImage: "pencil")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .glassEffect(in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
    }
}

// MARK: - Preview

#Preview("Normal") {
    NavigationStack {
        BottomPinDetailView(
            location: Location(
                name:       "Titik 1",
                coordinate: .init(latitude: -6.292363, longitude: 106.644227),
                altitude:   12,
                emoji:      "mappin",
                notes:      ""
            ),
            userLocation:      CLLocation(latitude: -6.293000, longitude: 106.645000),
            isWatchNavigating: false,
            onNavigate: {},
            onEdit:     {}
        )
    }
    .frame(height: 270)
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Watch Navigating") {
    NavigationStack {
        BottomPinDetailView(
            location: Location(
                name:       "Titik 1",
                coordinate: .init(latitude: -6.292363, longitude: 106.644227),
                altitude:   12,
                emoji:      "mappin",
                notes:      ""
            ),
            userLocation:      CLLocation(latitude: -6.293000, longitude: 106.645000),
            isWatchNavigating: true,
            onNavigate: {},
            onEdit:     {}
        )
    }
    .frame(height: 270)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
