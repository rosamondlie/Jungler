//
//  MainView.swift
//  Navee
//

import SwiftUI
import MapKit
import CoreLocation
import SwiftData

struct MainView: View {

    @EnvironmentObject private var session: TrekSession
    @Environment(\.modelContext) private var context

    @ObservedObject private var phoneSession = PhoneSessionManager.shared

    @Query(sort: \Location.timestamp)
    private var locations: [Location]

    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: MapConfig.defaultCenter,
            latitudinalMeters: MapConfig.defaultSpan,
            longitudinalMeters: MapConfig.defaultSpan
        )
    )

    @StateObject private var tracker            = LocationTracker()
    @State private var sheetContent:            MarkSheetContent? = nil
    @State private var compassDestinationIndex: Int?              = nil
    @State private var showEndConfirm:          Bool              = false
    @State private var mapSnapTask:             Task<Void, Never>? = nil

    private let detailSheetHeight: CGFloat = 260

    // MARK: - Computed

    private var isWatchNavigating: Bool {
        phoneSession.navigationOwner == .watch
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            mapLayer

            if session.isTracking {
                TrackingToolbar(
                    pinCount:    locations.count,
                    onShowMarks: { sheetContent = .list },
                    onAddMark:   addMark,
                    onEndTrek:   { showEndConfirm = true }
                )
            }

            // ── Banner: Watch sedang navigasi ──
            if isWatchNavigating {
                watchNavigationBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: phoneSession.navigationOwner)
        .fullScreenCover(isPresented: Binding(
            get: { !session.isTracking },
            set: { if !$0 { session.start() } }
        )) {
            StartOverlay { session.start() }
        }
        .sheet(isPresented: sheetIsPresented) {
            UnifiedMarkSheet(
                locations:         locations,
                content:           $sheetContent,
                userLocation:      tracker.userLocation,
                isWatchNavigating: isWatchNavigating,
                onNavigate:        handleNavigate,
                onSelectOnMap:     handleSelectOnMap,
                onDelete:          deletePin,
                onUpdate:          { }
            )
        }
        .fullScreenCover(isPresented: compassNavigationBinding) {
            if let idx = compassDestinationIndex {
                CompassNavigationView(
                    allLocations:     locations,
                    destinationIndex: idx,
                    onEndNavigation:  { compassDestinationIndex = nil }
                )
            }
        }
        .alert("End Trekking?", isPresented: $showEndConfirm) {
            Button("End", role: .destructive) { endTrekking() }
            Button("Cancel", role: .cancel)   { }
        } message: {
            Text("Your saved points will remain. You'll return to the start screen.")
        }
        .onAppear {
            phoneSession.syncSavedLocations(locations)
        }
        .onChange(of: locations) { _, newLocations in
            phoneSession.syncSavedLocations(newLocations)
        }
        .onChange(of: phoneSession.shouldStopNavigation) { _, should in
            if should {
                compassDestinationIndex = nil
                phoneSession.shouldStopNavigation = false
            }
        }
    }

    // MARK: - Watch Navigation Banner

    private var watchNavigationBanner: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "applewatch")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Navigasi berjalan di Watch")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    if let destName = watchDestinationName {
                        Text(destName)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button {
                    handleTakeOverFromWatch()
                } label: {
                    Text("Lanjutkan di sini")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.35, green: 0.95, blue: 0.55))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal, 12)
            .padding(.bottom, 96)
        }
    }

    private var watchDestinationName: String? {
        guard let data = phoneSession.watchNavData,
              data.destinationIndex < data.locations.count else { return nil }
        return data.locations[data.destinationIndex].name
    }

    // MARK: - Map Layer

    private var mapLayer: some View {
        GeometryReader { _ in
            Map(position: $mapPosition) {
                if let userCoord = tracker.userLocation?.coordinate {
                    Annotation("", coordinate: userCoord, anchor: .center) {
                        FootstepMarker().allowsHitTesting(false)
                    }
                }
                ForEach(locations) { location in
                    Annotation("", coordinate: location.coordinate, anchor: .bottom) {
                        DynamicTearDropPin(
                            location:   location,
                            isSelected: isSelected(location),
                            onTap:      { handlePinTap(location) }
                        )
                        .zIndex(isSelected(location) ? 1 : 0)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .preferredColorScheme(.dark)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
                MapScaleView()
            }
            .safeAreaInset(edge: .bottom) {
                if isDetailVisible {
                    Color.clear.frame(height: detailSheetHeight)
                }
            }
            .onMapCameraChange(frequency: .onEnd) { _ in
                scheduleSnapToDetail()
            }
            .onAppear {
                tracker.startTracking()
                centerMapOnUser()
            }
        }
    }

    // MARK: - Computed Properties

    private var isDetailVisible: Bool {
        if case .detail = sheetContent { return true }
        return false
    }

    private var sheetIsPresented: Binding<Bool> {
        Binding(
            get: { sheetContent != nil },
            set: { if !$0 { sheetContent = nil } }
        )
    }

    private var compassNavigationBinding: Binding<Bool> {
        Binding(
            get: { compassDestinationIndex != nil },
            set: {
                if !$0 {
                    compassDestinationIndex = nil
                    phoneSession.stopNavigation()
                }
            }
        )
    }

    private func isSelected(_ location: Location) -> Bool {
        if case .detail(let l) = sheetContent { return l.id == location.id }
        return false
    }

    // MARK: - Auto-Snap

    private func scheduleSnapToDetail() {
        guard case .detail(let location) = sheetContent else { return }
        mapSnapTask?.cancel()
        mapSnapTask = Task {
            do { try await Task.sleep(for: .milliseconds(1200)) } catch { return }
            guard !Task.isCancelled else { return }
            await MainActor.run { centerMap(on: location.coordinate) }
        }
    }

    // MARK: - Actions

    private func endTrekking() {
        mapSnapTask?.cancel()
        sheetContent            = nil
        compassDestinationIndex = nil
        phoneSession.stopAll() 
        phoneSession.stopNavigation()
        tracker.stopTracking()
        for location in locations { context.delete(location) }
        phoneSession.syncSavedLocations([])   // ← beritahu Watch bahwa semua lokasi sudah dihapus
        session.end()
    }

    private func handlePinTap(_ location: Location) {
        if case .detail(let current) = sheetContent, current.id == location.id {
            mapSnapTask?.cancel()
            sheetContent = nil
        } else {
            sheetContent = .detail(location)
            centerMap(on: location.coordinate)
        }
    }

    private func handleNavigate(_ location: Location) {
        guard phoneSession.navigationOwner != .watch else { return }

        mapSnapTask?.cancel()
        sheetContent = nil

        if let idx = locations.firstIndex(where: { $0.id == location.id }) {
            compassDestinationIndex = idx
            phoneSession.startNavigation(locations: locations, destinationIndex: idx)
        }
    }

    private func handleTakeOverFromWatch() {
        guard let watchData = phoneSession.watchNavData,
              watchData.destinationIndex < watchData.locations.count else { return }

        let destWatchLoc = watchData.locations[watchData.destinationIndex]

        guard let matchingIdx = locations.firstIndex(where: { $0.id == destWatchLoc.id }) else {
            phoneSession.takeOverFromWatch()
            return
        }

        phoneSession.takeOverFromWatch()
        phoneSession.startNavigation(locations: locations, destinationIndex: matchingIdx)
        compassDestinationIndex = matchingIdx
    }

    private func handleSelectOnMap(_ location: Location) {
        centerMap(on: location.coordinate)
    }

    private func deletePin(_ location: Location) {
        mapSnapTask?.cancel()
        if case .detail(let l) = sheetContent, l.id == location.id {
            sheetContent = nil
        }
        context.delete(location)
    }

    private func addMark() {
        guard let location = tracker.currentLocation() else {
            print("[AddMark] Lokasi belum tersedia")
            return
        }
        let pin = Location(
            name:       "Checkpoint \(locations.count + 1)",
            coordinate: location.coordinate,
            altitude:   location.altitude,
            emoji:      "mappin"
        )
        context.insert(pin)
    }

    private func centerMap(on coord: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.6)) {
            mapPosition = .region(MKCoordinateRegion(
                center: coord,
                latitudinalMeters: MapConfig.defaultSpan,
                longitudinalMeters: MapConfig.defaultSpan
            ))
        }
    }

    private func centerMapOnUser() {
        Task {
            for try await update in CLLocationUpdate.liveUpdates() {
                guard let coord = update.location?.coordinate else { continue }
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        mapPosition = .region(MKCoordinateRegion(
                            center: coord,
                            latitudinalMeters: MapConfig.defaultSpan,
                            longitudinalMeters: MapConfig.defaultSpan
                        ))
                    }
                }
                break
            }
        }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview { MainView() }
