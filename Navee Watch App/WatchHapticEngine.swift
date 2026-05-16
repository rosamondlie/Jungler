//
//  WatchHapticEngine.swift
//  naveeWatch Watch App
//
//  Created by neena on 16/05/26.
//

import WatchKit

struct WatchHapticEngine {
    static func arrived()     { WKInterfaceDevice.current().play(.success)      }
    static func checkpoint()  { WKInterfaceDevice.current().play(.notification) }
    static func backOnTrack() { WKInterfaceDevice.current().play(.click)        }
    static func wrongWay()    { WKInterfaceDevice.current().play(.failure)      }
}
