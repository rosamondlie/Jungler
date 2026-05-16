//
//  WatchNavigationView.swift
//  Navee Watch App
//
//  Created by neena on 16/05/26.
//

import SwiftUI
import CoreLocation
import WatchConnectivity

// MARK: - WatchNavigationView

struct WatchNavigationView: View {
    let allLocations: [WatchLocation]
    let destinationIndex: Int
    var onEndNavigation: () -> Void

    @StateObject private var tracker  = WatchLocationTracker()
    @State private var nav            = NavState()
    @State private var currentStep    = 0
    @State private var wasArrived     = false
    @State private var showEndConfirm = false
    @State private var finalArrivedSticky   = false

    @State private var isProcessingArrival  = false
    @State private var showCheckpointFlash  = false

    // MARK: - Computed

    private var breadcrumbs: [WatchLocation] {
        guard destinationIndex < allLocations.count else { return [] }
        let last = allLocations.count - 1
        guard last > destinationIndex else { return [allLocations[destinationIndex]] }
        return (destinationIndex...last).reversed().map { allLocations[$0] }
    }

    private var currentTarget: WatchLocation?    { breadcrumbs[safe: currentStep] }
    private var finalDestination: WatchLocation? { breadcrumbs.last }
    private var totalSteps: Int                  { breadcrumbs.count }
    private var isLastStep: Bool                 { currentStep >= totalSteps - 1 }
    private var finalArrivedComputed: Bool       { nav.hasArrived && isLastStep }

    private var formattedDistance: String {
        nav.distance < 1000
            ? "\(Int(nav.distance)) m"
            : String(format: "%.1f km", nav.distance / 1000)
    }

    private var cardinalDirection: String {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        return dirs[Int((nav.bearing + 22.5) / 45) % 8]
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let compassSize = w * 0.60

            ZStack {
                Color.black.ignoresSafeArea()

                if finalArrivedSticky {
                    WatchArrivalView(
                        destinationName: finalDestination?.name ?? "",
                        onDone: handleDone
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))

                } else {
                    VStack(spacing: 8) {

                        // Nama tujuan
                        if let target = currentTarget {
                            Text(target.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .padding(.horizontal, 8)
                                .frame(height: h * 0.10)
                        }

                        // Kompas
                        WatchCompassView(nav: nav)
                            .frame(width: compassSize, height: compassSize)
                            .padding(.horizontal, 8)

                        // Jarak + arah + step — 1 baris
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(formattedDistance)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(cardinalDirection)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(
                                    nav.isOnTrack
                                        ? Color(red: 0.2, green: 1, blue: 0.5)
                                        : .white.opacity(0.5)
                                )
                            if totalSteps > 1 {
                                Text("·")
                                    .foregroundColor(.white.opacity(0.3))
                                    .font(.system(size: 13))
                                Text("Step \(currentStep + 1)/\(totalSteps)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .frame(height: h * 0.10)

//                        Spacer(minLength: 12)

                        // Tombol End
                        Button {
                            showEndConfirm = true
                        } label: {
                            Text("End")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(Color(red: 0.85, green: 0.15, blue: 0.15))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                    }
                    .frame(width: w, height: h)

                    // Checkpoint flash overlay
                    if showCheckpointFlash {
                        WatchCheckpointFlash()
                            .transition(.opacity)
                            .allowsHitTesting(false)
                    }
                }
            }
            .frame(width: w, height: h)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: finalArrivedSticky)
        .animation(.easeInOut(duration: 0.2), value: showCheckpointFlash)
        .onAppear {
            tracker.startTracking()
        }
        .onDisappear {
            tracker.stopTracking()
        }
        .onChange(of: tracker.heading) { _, heading in
            nav.userHeading = heading
            if !nav.hasValidHeading { nav.hasValidHeading = true }
            updateNav(from: tracker.userLocation)
        }
        .onChange(of: tracker.userLocation) { _, location in
            updateNav(from: location)
            checkArrival()
        }
        .onChange(of: finalArrivedComputed) { _, arrived in
            if arrived { finalArrivedSticky = true }
        }
        .alert("End Navigation?", isPresented: $showEndConfirm) {
            Button("End", role: .destructive) { handleDone() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Navigation will be stopped.")
        }
    }

    // MARK: - Actions

    private func handleDone() {
        tracker.stopTracking()
        notifyPhoneNavigationEnded()
        onEndNavigation()
    }

    private func notifyPhoneNavigationEnded() {
        guard WCSession.default.activationState == .activated else { return }
        let msg: [String: Any] = ["stopNavigation": true]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(msg, replyHandler: nil, errorHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(msg)
        }
    }

    // MARK: - Nav Logic

    private func updateNav(from location: CLLocation?) {
        guard let coord = location?.coordinate,
              let target = currentTarget else { return }
        nav.bearing  = coord.bearing(to: target.coordinate)
        nav.distance = coord.distance(to: target.coordinate)
    }

    private func checkArrival() {
        guard !finalArrivedSticky      else { return }
        guard nav.hasArrived           else { return }
        guard !isLastStep              else { return }
        guard !isProcessingArrival     else { return }

        isProcessingArrival = true
        WatchHapticEngine.checkpoint()

        withAnimation { showCheckpointFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showCheckpointFlash = false }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.4)) { currentStep += 1 }
            wasArrived = false
            updateNav(from: tracker.userLocation)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isProcessingArrival = false
            }
        }
    }
}

// MARK: - WatchCheckpointFlash

private struct WatchCheckpointFlash: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.25))
                        .frame(width: 52, height: 52)
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.95, blue: 0.55))
                }

                Text("Checkpoint!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text("Lanjut ke titik berikutnya")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.12).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.75)
                    )
            )
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - WatchArrivalView

private struct WatchArrivalView: View {
    let destinationName: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.22))
                    .frame(width: 54, height: 54)
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.95, blue: 0.55),
                                Color(red: 0.20, green: 0.78, blue: 0.35)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("You've Arrived!")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)

            Text(destinationName)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
                .lineLimit(1)

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.20, green: 0.78, blue: 0.35))
                .font(.system(size: 13, weight: .semibold))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .interactiveDismissDisabled(true)
    }
}
