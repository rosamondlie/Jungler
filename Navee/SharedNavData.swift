//
//  SharedNavData.swift
//  Navee
//
//  Created by neena on 16/05/26.
//

import CoreLocation

// Lightweight struct untuk transfer data iOS ↔ Watch
// (Location pakai @Model SwiftData, tidak bisa di-share langsung ke Watch)

struct WatchLocation: Codable, Identifiable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let emoji: String
    let notes: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct WatchNavData: Codable {
    let locations: [WatchLocation]
    let destinationIndex: Int
}
