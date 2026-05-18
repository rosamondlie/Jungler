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

    @Published var watchLocations: [WatchLocation]  = []
    @Published var destinationIndex: Int            = 0
    @Published var isNavigating: Bool               = false
    @Published var savedLocations: [WatchLocation]  = []
    @Published var showLocationPicker: Bool         = false
    @Published var navigationOwner: NavigationOwner = .none
    @Published var phoneNavData: WatchNavData?      = nil
    @Published var initialNavigationStep: Int       = 0

    // MARK: - Init

    private override init() {
        super.init()
        loadSavedLocations()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Public API

    func startStandaloneNavigation(to destination: WatchLocation) {
        guard let idx = savedLocations.firstIndex(where: { $0.id == destination.id }) else { return }
        watchLocations        = savedLocations
        destinationIndex      = idx
        initialNavigationStep = 0
        navigationOwner       = .watch
        withAnimation { isNavigating = true }
        broadcastWatchNav(step: 0)
    }

    func takeOverFromPhone() {
        guard let phoneData = phoneNavData else { return }
        watchLocations        = phoneData.locations
        destinationIndex      = phoneData.destinationIndex
        initialNavigationStep = phoneData.currentStep
        navigationOwner       = .watch
        phoneNavData          = nil
        sendToPhone(["takeOver": "watch"])
        withAnimation { isNavigating = true }
        broadcastWatchNav(step: phoneData.currentStep)
    }

    func broadcastCurrentStep(_ step: Int) {
        guard navigationOwner == .watch else { return }
        broadcastWatchNav(step: step)
    }

    func endNavigation() {
        navigationOwner = .none
        phoneNavData    = nil
        sendToPhone(["stopNavigation": true])
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        let ctx = WCSession.default.receivedApplicationContext
        guard !ctx.isEmpty else { return }

        // Jangan restore state navigasi dari context lama — tunggu update fresh dari HP
        if let status = ctx["navStatus"] as? String, status == "phone_navigating" {
            return
        }

        // Proses stopNavigation dari context jika ada
        if let stop = ctx["stopNavigation"] as? Bool, stop {
            DispatchQueue.main.async {
                withAnimation { self.resetNavigationState() }
            }
            return
        }

        // Restore savedLocations saja
        if let data = ctx["savedLocations"] as? Data,
           let locs = try? JSONDecoder().decode([WatchLocation].self, from: data) {
            DispatchQueue.main.async {
                self.savedLocations = locs
                self.persistSavedLocations(locs)
            }
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext context: [String: Any]) {
        handle(context)
    }

    // MARK: - Private

    private func broadcastWatchNav(step: Int) {
        let navData = WatchNavData(
            locations: watchLocations,
            destinationIndex: destinationIndex,
            currentStep: step,
            owner: .watch
        )
        guard let data = try? JSONEncoder().encode(navData) else { return }
        sendToPhone(["navData": data])
    }

    private func sendToPhone(_ message: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(message)
        }
    }

    private func resetNavigationState() {
        isNavigating          = false
        navigationOwner       = .none
        phoneNavData          = nil
        watchLocations        = []
        destinationIndex      = 0
        initialNavigationStep = 0
        showLocationPicker    = false
    }

    private func handle(_ msg: [String: Any]) {
        if let stop = msg["stopNavigation"] as? Bool, stop {
            DispatchQueue.main.async {
                withAnimation { self.resetNavigationState() }
            }
            return
        }

        if let takeOver = msg["takeOver"] as? String, takeOver == "phone" {
            DispatchQueue.main.async {
                withAnimation {
                    self.isNavigating    = false
                    self.navigationOwner = .phone
                    self.phoneNavData    = nil
                    self.watchLocations  = []
                }
            }
            return
        }

        if let status = msg["navStatus"] as? String {
            switch status {
            case "phone_navigating":
                if let data = msg["navigationData"] as? Data,
                   let navData = try? JSONDecoder().decode(WatchNavData.self, from: data) {
                    DispatchQueue.main.async {
                        self.phoneNavData = navData
                        if !self.isNavigating {
                            self.navigationOwner = .phone
                        }
                    }
                }
            case "idle":
                DispatchQueue.main.async {
                    self.phoneNavData = nil
                    if self.navigationOwner == .phone {
                        self.navigationOwner = .none
                    }
                }
            default:
                break
            }
        }

        if let data = msg["savedLocations"] as? Data,
           let locs = try? JSONDecoder().decode([WatchLocation].self, from: data) {
            DispatchQueue.main.async {
                self.savedLocations = locs
                self.persistSavedLocations(locs)
            }
        }
    }

    // MARK: - Persistence

    private let savedLocationsKey = "navee.savedLocations"

    private func persistSavedLocations(_ locations: [WatchLocation]) {
        guard let data = try? JSONEncoder().encode(locations) else { return }
        UserDefaults.standard.set(data, forKey: savedLocationsKey)
    }

    private func loadSavedLocations() {
        guard let data = UserDefaults.standard.data(forKey: savedLocationsKey),
              let locs = try? JSONDecoder().decode([WatchLocation].self, from: data)
        else { return }
        savedLocations = locs
    }
}
