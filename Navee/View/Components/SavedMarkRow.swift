//
//  SavedMarkRow.swift
//  Navee
//

import SwiftUI
import CoreLocation

struct SavedMarkRow: View {
    let location:     Location
    var userLocation: CLLocation?
    var onSelect:     () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PinIconBox(emoji: location.emoji)

            VStack(alignment: .leading, spacing: 8) {
                Text(location.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                LocationMetaRow(location: location, userLocation: userLocation)
            }

            Spacer()
        }
        .padding(.vertical, 20)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}

// MARK: - Preview

#Preview {
    List {
        SavedMarkRow(
            location: Location(
                name:       "Titik 1",
                coordinate: .init(latitude: -6.292363, longitude: 106.644227),
                altitude:   12,
                emoji:      "tent.fill",
                notes:      ""
            ),
            userLocation: CLLocation(latitude: -6.293, longitude: 106.645),
            onSelect: {}
        )
        .listRowBackground(Color.black)
    }
    .listStyle(.plain)
    .preferredColorScheme(.dark)
}
