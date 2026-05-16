//
//  naveeWatchApp.swift
//  navee Watch App
//
//  Created by neena on 16/05/26.
//

import SwiftUI

@main
struct naveeWatchApp: App {
    // Inisialisasi WatchSessionManager lebih awal agar tidak miss pesan dari iPhone
    @StateObject private var session = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
