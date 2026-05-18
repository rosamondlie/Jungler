//
//  CompassNavigationView.swift
//  Navee
//

import SwiftUI
import CoreLocation

struct CompassNavigationView: View {
    let allLocations: [Location]
    let destinationIndex: Int
    var onEndNavigation: () -> Void

    @StateObject private var tracker      = LocationTracker()
    @StateObject private var phoneSession = PhoneSessionManager.shared  // ✅ terima sinyal dari Watch

    @State private var nav               = NavState()
    @State private var currentStep       = 0
    @State private var arrivalFlash: ArrivalKind? = nil
    @State private var flashOpacity: Double = 0
    @State private var wasOnTrack        = true
    @State private var wasArrived        = false
    @State private var showEndConfirm    = false

    // ✅ Sticky flag — sama seperti di Watch, tidak bisa balik false meski GPS goyang
    @State private var finalArrivedSticky = false

    // MARK: - Computed Properties

    private var breadcrumbs: [Location] {
        guard destinationIndex < allLocations.count else { return [] }
        let lastIndex = allLocations.count - 1
        guard lastIndex > destinationIndex else {
            return [allLocations[destinationIndex]]
        }
        return (destinationIndex...lastIndex).reversed().map { allLocations[$0] }
    }

    private var currentTarget: Location?    { breadcrumbs[safe: currentStep] }
    private var finalDestination: Location? { breadcrumbs.last }
    private var totalSteps: Int             { breadcrumbs.count }
    private var isLastStep: Bool            { currentStep >= totalSteps - 1 }

    // Hanya untuk men-trigger sticky flag — tidak dipakai langsung di UI
    private var finalArrivedComputed: Bool  { nav.hasArrived && isLastStep }

    private var pointsPassed: Int           { nav.hasArrived ? currentStep + 1 : currentStep }

    private var distanceToFinal: Double {
        guard let userLocation = tracker.userLocation else { return 0 }
        let remaining = Array(breadcrumbs.dropFirst(currentStep))
        guard !remaining.isEmpty else { return 0 }
        var total = 0.0
        var prev  = userLocation.coordinate
        for waypoint in remaining {
            total += prev.distance(to: waypoint.coordinate)
            prev   = waypoint.coordinate
        }
        return total
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    if let target = currentTarget {
                        CompassView(nav: nav, destination: target)
                            .padding(.horizontal, 32)
                    }
                    StatusLabel(nav: nav, finalArrived: finalArrivedSticky)
                        .padding(.top, 28)
                }
                Spacer(minLength: 32)
                Color.clear.frame(height: 200)
            }

            BottomNavCard(
                nav:              nav,
                finalArrived:     finalArrivedSticky,
                currentTarget:    currentTarget,
                finalDestination: finalDestination,
                distanceToFinal:  distanceToFinal,
                currentStep:      currentStep,
                pointsPassed:     pointsPassed,
                totalSteps:       totalSteps,
                onEndNavigation: {
                    showEndConfirm = true
                },
                onExit: {
                    handleDone()
                }
            )

            if let flash = arrivalFlash, flash == .checkpoint {
                ArrivalFlashOverlay(kind: flash, opacity: flashOpacity)
                    .allowsHitTesting(false)
            }

            // ✅ Pakai finalArrivedSticky — tidak hilang sendiri meski GPS goyang
            if finalArrivedSticky {
                ArrivalOverlay(
                    destination: finalDestination,
                    onExit: handleDone
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: finalArrivedSticky)
        .alert("End Navigation?", isPresented: $showEndConfirm) {
            Button("End", role: .destructive) { handleDone() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your current navigation session will be stopped.")
        }
        .onAppear {
            tracker.startTracking()
            PhoneSessionManager.shared.startNavigation(
                locations: allLocations,
                destinationIndex: destinationIndex
            )
        }
        .onDisappear {
            tracker.stopTracking()
            PhoneSessionManager.shared.stopNavigation()
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
        .onChange(of: nav.isOnTrack) { _, onTrack in
            guard !nav.hasArrived else { return }
            onTrack ? HapticEngine.backOnTrack() : HapticEngine.wrongWay()
        }
        .onChange(of: nav.hasArrived) { _, arrived in
            if arrived && !wasArrived { HapticEngine.arrived() }
            wasArrived = arrived
        }
        // ✅ Sync currentStep ke Watch setiap kali user maju ke checkpoint berikutnya
        .onChange(of: currentStep) { _, step in
            PhoneSessionManager.shared.updateCurrentStep(step)
        }
        // ✅ Set sticky flag saat computed value jadi true — tidak pernah di-unset dari sini
        .onChange(of: finalArrivedComputed) { _, arrived in
            if arrived { finalArrivedSticky = true }
        }
        // ✅ Terima sinyal dari Watch (user pencet Done di jam) → stop di iPhone juga
        .onChange(of: phoneSession.shouldStopNavigation) { _, should in
            if should {
                phoneSession.shouldStopNavigation = false
                handleDone()
            }
        }
    }

    // MARK: - Actions

    /// Entry point tunggal untuk mengakhiri navigasi — dari Done, End, atau sinyal Watch
    private func handleDone() {
        tracker.stopTracking()
        PhoneSessionManager.shared.stopNavigation()
        onEndNavigation()
    }

    private func updateNav(from location: CLLocation?) {
        guard let coord = location?.coordinate, let target = currentTarget else { return }
        nav.bearing  = coord.bearing(to: target.coordinate)
        nav.distance = coord.distance(to: target.coordinate)
    }

    private func checkArrival() {
        guard !finalArrivedSticky else { return }  // sudah final, jangan proses checkpoint
        guard nav.hasArrived else { return }
        guard !isLastStep else { return }
        triggerFlash(.checkpoint) {
            withAnimation(.easeInOut(duration: 0.4)) { currentStep += 1 }
            wasArrived = false
            updateNav(from: tracker.userLocation)
        }
    }

    private func triggerFlash(_ kind: ArrivalKind, completion: (() -> Void)? = nil) {
        guard arrivalFlash == nil else { return }
        arrivalFlash = kind
        withAnimation(.easeOut(duration: 0.2)) { flashOpacity = 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeIn(duration: 0.35)) { flashOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                arrivalFlash = nil
                completion?()
            }
        }
    }
}

// MARK: - Arrival Overlay

private struct ArrivalOverlay: View {
    let destination: Location?
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.3),
                                    Color(red: 0.10, green: 0.60, blue: 0.25).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Circle()
                        .strokeBorder(
                            Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.4),
                            lineWidth: 1
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .semibold))
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
                .padding(.top, 36)
                .padding(.bottom, 20)

                Text("You've Arrived")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                if let name = destination?.name {
                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                        .padding(.top, 6)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.top, 32)

                Button(action: onExit) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 0.20, green: 0.78, blue: 0.35))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ModalButtonStyle())
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(red: 0.10, green: 0.10, blue: 0.11).opacity(0.65))
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.75)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 40)
            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Preview

#Preview {
    CompassNavigationView(
        allLocations: [
            Location(name: "Titik 1", coordinate: .init(latitude: -6.291, longitude: 106.643), altitude: 10, emoji: "mappin",     notes: ""),
            Location(name: "Titik 2", coordinate: .init(latitude: -6.292, longitude: 106.644), altitude: 20, emoji: "tent.fill",  notes: ""),
            Location(name: "Titik 3", coordinate: .init(latitude: -6.293, longitude: 106.645), altitude: 30, emoji: "flag.fill",  notes: ""),
            Location(name: "Titik 4", coordinate: .init(latitude: -6.294, longitude: 106.646), altitude: 40, emoji: "flame.fill", notes: ""),
        ],
        destinationIndex: 1,
        onEndNavigation: {}
    )
}
