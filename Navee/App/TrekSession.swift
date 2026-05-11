//
//  TrekSession.swift
//  Navee
//
//  Created by neena on 09/05/26.
//


import Foundation
import Combine

class TrekSession: ObservableObject {

    @Published private(set) var isTracking: Bool {
        didSet {
            UserDefaults.standard.set(isTracking, forKey: "trek_is_active")
        }
    }

    init() {
        self.isTracking = UserDefaults.standard.bool(forKey: "trek_is_active")
    }

    func start() { isTracking = true  }
    func end()   { isTracking = false }
}
