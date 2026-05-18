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

    // MARK: - Published State

    @Published var shouldStopNavigation: Bool = false
    @Published var navigationOwner: NavigationOwner = .none
    @Published var watchNavData: WatchNavData? = nil

    // MARK: - Private

    private var lastNavData: WatchNavData?
    private var ctxStore: [String: Any] = [:]

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        clearStaleContext() // ← bersihkan context lama saat launch
    }

    // MARK: - Public API

    func startNavigation(locations: [Location], destinationIndex: Int) {
        let watchLocs = locations.map { WatchLocation(from: $0) }
        let navData = WatchNavData(
            locations: watchLocs,
            destinationIndex: destinationIndex,
            currentStep: 0,
            owner: .phone
        )
        lastNavData     = navData
        navigationOwner = .phone

        guard let data = try? JSONEncoder().encode(navData) else { return }
        pushContext(["navStatus": "phone_navigating", "navigationData": data])
        sendLive(["navStatus": "phone_navigating", "navigationData": data])
    }

    func updateCurrentStep(_ step: Int) {
        guard var nav = lastNavData else { return }
        nav = WatchNavData(
            locations: nav.locations,
            destinationIndex: nav.destinationIndex,
            currentStep: step,
            owner: .phone
        )
        lastNavData = nav
        guard let data = try? JSONEncoder().encode(nav) else { return }
        pushContext(["navStatus": "phone_navigating", "navigationData": data])
    }

    func stopNavigation() {
        guard navigationOwner == .phone else { return }
        navigationOwner = .none
        lastNavData     = nil
        pushContext(["navStatus": "idle"])
        sendLive(["stopNavigation": true])
    }

    /// Panggil saat end trekking — stop Watch meski Watch yang sedang navigasi.
    func stopAll() {
        lastNavData     = nil
        navigationOwner = .none
        watchNavData    = nil
        pushContext(["navStatus": "idle"])
        sendLive(["stopNavigation": true])
        var fallbackCtx = ctxStore
        fallbackCtx["stopNavigation"] = true
        try? WCSession.default.updateApplicationContext(fallbackCtx)
    }

    func takeOverFromWatch() {
        watchNavData    = nil
        navigationOwner = .none
        sendLive(["takeOver": "phone"])
        try? WCSession.default.updateApplicationContext(["takeOver": "phone"])
    }

    func syncSavedLocations(_ locations: [Location]) {
        let watchLocs = locations.map { WatchLocation(from: $0) }
        guard let data = try? JSONEncoder().encode(watchLocs) else { return }
        pushContext(["savedLocations": data])
    }

    // MARK: - Context Store

    private func clearStaleContext() {
        ctxStore = [:]
        try? WCSession.default.updateApplicationContext([
            "navStatus": "idle",
            "stopNavigation": true
        ])
    }

    private func pushContext(_ updates: [String: Any]) {
        updates.forEach { ctxStore[$0.key] = $0.value }
        if let status = ctxStore["navStatus"] as? String, status == "idle" {
            ctxStore.removeValue(forKey: "navigationData")
        }
        try? WCSession.default.updateApplicationContext(ctxStore)
    }

    // MARK: - Messaging

    private func sendLive(_ message: [String: Any]) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("[PhoneSession] sendMessage error: \(error.localizedDescription)")
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

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        handleFromWatch(message)
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext context: [String: Any]) {
        handleFromWatch(context)
    }

    // MARK: - Handle Incoming (dari Watch)

    private func handleFromWatch(_ msg: [String: Any]) {
        if let stop = msg["stopNavigation"] as? Bool, stop {
            DispatchQueue.main.async {
                if self.navigationOwner == .watch {
                    self.navigationOwner = .none
                    self.watchNavData    = nil
                }
            }
            return
        }

        if let takeOver = msg["takeOver"] as? String, takeOver == "watch" {
            DispatchQueue.main.async {
                self.shouldStopNavigation = true
                self.navigationOwner      = .watch
            }
            return
        }

        if let data = msg["navData"] as? Data,
           let navData = try? JSONDecoder().decode(WatchNavData.self, from: data),
           navData.owner == .watch {
            DispatchQueue.main.async {
                guard self.navigationOwner != .phone else { return }
                self.watchNavData    = navData
                self.navigationOwner = .watch
            }
        }
    }
}

// MARK: - WatchLocation convenience init

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
