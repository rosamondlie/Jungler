// LocationModel.swift

import Foundation
import SwiftData
import CoreLocation

@Model
class Location {

    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var altitude: Double
    var emoji: String
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        altitude: Double,
        emoji: String,
        notes: String = ""
    ) {
        self.id        = id
        self.name      = name
        self.latitude  = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.altitude  = altitude
        self.emoji     = emoji
        self.notes     = notes
    }

    // Convenience init yang tetap terima CLLocationCoordinate2D
    // supaya call site lama tidak perlu banyak berubah
    convenience init(
        id: UUID = UUID(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        timestamp: Date = Date(),
        altitude: Double,
        emoji: String,
        notes: String = ""
    ) {
        self.init(
            id:        id,
            name:      name,
            latitude:  coordinate.latitude,
            longitude: coordinate.longitude,
            timestamp: timestamp,
            altitude:  altitude,
            emoji:     emoji,
            notes:     notes
        )
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
