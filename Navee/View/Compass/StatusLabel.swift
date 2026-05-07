//
//  StatusLabel.swift
//  Navee
//
//  Created by neena on 06/05/26.
//

import SwiftUI

struct StatusLabel: View {
    let nav: NavState
    let finalArrived: Bool

    private var noGPS: Bool { nav.distance == 0 || !nav.hasValidHeading }

    private var label: String {
        if noGPS        { return "Finding Location" }
        if finalArrived { return "Arrived!" }
        return nav.isOnTrack ? "Heading Right" : "Slightly Off"
    }

    private var subtitle: String {
        if noGPS        { return "Looking for a GPS signal..." }
        if finalArrived { return "You have reached your destination" }
        return nav.isOnTrack
            ? "Keep heading this way"
            : "Turn slightly toward your destination"
    }

    private var labelColor: Color {
        if noGPS        { return .white.opacity(0.35) }
        if finalArrived { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return nav.isOnTrack
            ? Color(red: 0.20, green: 0.78, blue: 0.35)
            : Color(red: 1.0,  green: 0.27, blue: 0.23)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(labelColor)
                .kerning(0.5)

            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .animation(.easeInOut(duration: 0.25), value: label)
    }
}
