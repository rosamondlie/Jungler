//
//  LocationMetaRow.swift
//  Navee
//
//  Created by neena on 07/05/26.
//

import SwiftUI
import CoreLocation

/// Baris info jarak + altitude yang dipakai di SavedMarkRow & BottomPinDetailView.
struct LocationMetaRow: View {
    let location: Location
    var userLocation: CLLocation?

    var body: some View {
        HStack(spacing: 6) {
            Text(location.formattedDistance(from: userLocation))
            Text("·").opacity(0.4)
            Text("\(Int(location.altitude)) masl")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
}
