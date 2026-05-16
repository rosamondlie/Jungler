//
//  PhoneSessionManager.swift
//  Navee
//
//  Created by neena on 16/05/26.
//

import WatchConnectivity
import Combine

class PhoneSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneSessionManager()

    // ✅ iPhone observe ini — kalau Watch selesai navigasi, iPhone ikut berhenti
    @Published var shouldStopNavigation: Bool = false

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Public API

    /// Panggil saat user mulai navigasi di iPhone → Watch ikut navigasi
    func startNavigation(locations: [Location], destinationIndex: Int) {
        let watchLocations = locations.map { WatchLocation(from: $0) }
        let navData = WatchNavData(locations: watchLocations,
                                   destinationIndex: destinationIndex)
        guard let data = try? JSONEncoder().encode(navData) else { return }
        send(["navigationData": data])
    }

    /// Panggil saat navigasi selesai/dibatalkan di iPhone → beritahu Watch
    func stopNavigation() {
        send(["stopNavigation": true])
    }

    /// Sync semua saved locations ke Watch untuk navigasi standalone.
    /// Panggil saat app launch atau saat user tambah/hapus lokasi.
    func syncSavedLocations(_ locations: [Location]) {
        let watchLocations = locations.map { WatchLocation(from: $0) }
        guard let data = try? JSONEncoder().encode(watchLocations) else { return }
        try? WCSession.default.updateApplicationContext(["savedLocations": data])
    }

    // MARK: - Private

    private func send(_ message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("[PhoneSession] sendMessage error: \(error.localizedDescription)")
            }
        } else {
            try? WCSession.default.updateApplicationContext(message)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    /// ✅ Terima pesan dari Watch — misal Watch pencet Done saat sudah tiba
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        handleFromWatch(message)
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext context: [String: Any]) {
        handleFromWatch(context)
    }

    private func handleFromWatch(_ message: [String: Any]) {
        if let stop = message["stopNavigation"] as? Bool, stop {
            DispatchQueue.main.async {
                self.shouldStopNavigation = true
            }
        }
    }
}

// MARK: - WatchLocation convenience init dari Location (iPhone model)

extension WatchLocation {
    init(from location: Location) {
        self.init(
            id:        location.id,
            name:      location.name,
            latitude:  location.latitude,
            longitude: location.longitude,
            altitude:  location.altitude,
            emoji:     location.emoji,
            notes:     location.notes
        )
    }
}
