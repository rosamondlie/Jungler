//
//  WatchSessionManager.swift
//  Navee Watch App
//
//  Created by neena on 16/05/26.
//

import WatchConnectivity
import Combine
import SwiftUI

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    // MARK: - Published State

    @Published var watchLocations: [WatchLocation] = []
    @Published var destinationIndex: Int = 0
    @Published var isNavigating: Bool = false
    @Published var savedLocations: [WatchLocation] = []
    @Published var showLocationPicker: Bool = false

    // MARK: - Init

    private override init() {
        super.init()
        loadSavedLocations()
        print("[WatchSession] Loaded \(savedLocations.count) saved locations from disk.")
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Public API

    func startStandaloneNavigation(to destination: WatchLocation) {
        guard let destIndex = savedLocations.firstIndex(where: { $0.id == destination.id })
        else { return }
        watchLocations   = savedLocations
        destinationIndex = destIndex
        withAnimation { isNavigating = true }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        print("[WatchSession] Activated: \(state.rawValue), error: \(String(describing: error))")
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        print("[WatchSession] didReceiveMessage keys: \(message.keys.joined(separator: ", "))")
        handle(message)
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext context: [String: Any]) {
        print("[WatchSession] didReceiveApplicationContext keys: \(context.keys.joined(separator: ", "))")
        handle(context)
    }

    // MARK: - Private

    private func handle(_ message: [String: Any]) {
        // Stop navigasi
        if let stop = message["stopNavigation"] as? Bool, stop {
            DispatchQueue.main.async { self.isNavigating = false }
            return
        }

        // Navigasi aktif dari iPhone
        if let data    = message["navigationData"] as? Data,
           let navData = try? JSONDecoder().decode(WatchNavData.self, from: data) {
            print("[WatchSession] Received navigationData: \(navData.locations.count) locations, dest \(navData.destinationIndex)")
            DispatchQueue.main.async {
                self.watchLocations   = navData.locations
                self.destinationIndex = navData.destinationIndex
                self.isNavigating     = true
            }
        }

        // Saved locations untuk standalone
        if let data      = message["savedLocations"] as? Data,
           let locations = try? JSONDecoder().decode([WatchLocation].self, from: data) {
            print("[WatchSession] Received savedLocations: \(locations.count) locations")
            DispatchQueue.main.async {
                self.savedLocations = locations
                self.persistSavedLocations(locations)
            }
        }
    }

    // MARK: - Persistence

    private let savedLocationsKey = "navee.savedLocations"

    private func persistSavedLocations(_ locations: [WatchLocation]) {
        guard let data = try? JSONEncoder().encode(locations) else { return }
        UserDefaults.standard.set(data, forKey: savedLocationsKey)
        UserDefaults.standard.synchronize()
    }

    private func loadSavedLocations() {
        guard let data      = UserDefaults.standard.data(forKey: savedLocationsKey),
              let locations = try? JSONDecoder().decode([WatchLocation].self, from: data)
        else { return }
        savedLocations = locations
    }
}
