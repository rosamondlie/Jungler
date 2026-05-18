//
//  SharedNavData.swift
//  Navee
//
//  Created by neena on 16/05/26.
//

import CoreLocation

// MARK: - Navigation Owner

/// Satu perangkat saja yang boleh navigasi pada satu waktu.
enum NavigationOwner: String, Codable, Equatable {
    case phone, watch, none
}

// MARK: - WatchLocation

struct WatchLocation: Codable, Identifiable, Equatable {
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

// MARK: - WatchNavData

struct WatchNavData: Codable, Equatable {
    let locations: [WatchLocation]
    let destinationIndex: Int
    var currentStep: Int        // breadcrumb step yang sedang aktif
    var owner: NavigationOwner  // siapa yang sedang memegang sesi
}
