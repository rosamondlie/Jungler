//
//  NaveeApp.swift
//  Navee
//
//  Created by Rosamond Patricia Selamat Lie on 01/05/26.
//

import SwiftUI
import SwiftData

@main
struct NaveeApp: App {

    @StateObject private var session = TrekSession()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(session)
        }
        .modelContainer(for: Location.self)
    }
}
