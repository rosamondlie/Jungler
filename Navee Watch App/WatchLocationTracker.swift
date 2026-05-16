//
//  WatchLocationTracker.swift
//  naveeWatch Watch App
//
//  Created by neena on 16/05/26.
//

import Foundation
import CoreLocation
import CoreMotion
import Combine

class WatchLocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Published State

    @Published var userLocation: CLLocation?
    @Published var heading: Double = 0
    @Published var hasValidHeading: Bool = false

    // MARK: - Private

    private let locationManager = CLLocationManager()
    private let motionManager   = CMMotionManager()

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate        = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
    }

    // MARK: - Public API

    func startTracking() {
        startLocationUpdates()
        startHeadingUpdates()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - Private Helpers

    private func startLocationUpdates() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    private func startHeadingUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("[WatchLocationTracker] DeviceMotion tidak tersedia di perangkat ini.")
            return
        }

        // .xMagneticNorthZVertical → 0° = North, referensi magnetik (kompas)
        motionManager.deviceMotionUpdateInterval = 1.0 / 20
        motionManager.startDeviceMotionUpdates(
            using: .xMagneticNorthZVertical,
            to: .main
        ) { [weak self] motion, error in
            guard let self else { return }

            if let error {
                print("[WatchLocationTracker] Motion error: \(error.localizedDescription)")
                return
            }

            guard let motion else { return }

            // yaw dari CoreMotion: 0 = North, negatif = searah jarum jam
            // Konversi ke heading 0–360 seperti CLHeading
            let yawDegrees = motion.attitude.yaw * 180 / .pi
            let normalized = (-yawDegrees + 360).truncatingRemainder(dividingBy: 360)

            self.heading = normalized
            if !self.hasValidHeading { self.hasValidHeading = true }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last,
              latest.horizontalAccuracy >= 0,
              latest.horizontalAccuracy <= 20
        else { return }
        userLocation = latest
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("[WatchLocationTracker] GPS error: \(error.localizedDescription)")
    }
}
