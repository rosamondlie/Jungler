//
//  ContentView.swift
//  Navee Watch App
//
//  Created by neena on 16/05/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var session = WatchSessionManager.shared

    var body: some View {
        Group {
            if session.isNavigating && !session.watchLocations.isEmpty {
                // ── Watch sedang navigasi ──
                WatchNavigationView(
                    allLocations:     session.watchLocations,
                    destinationIndex: session.destinationIndex,
                    initialStep:      session.initialNavigationStep,
                    onEndNavigation:  {
                        withAnimation { session.isNavigating = false }
                        session.endNavigation()
                    }
                )

            } else if session.navigationOwner == .phone,
                      let phoneData = session.phoneNavData {
                // ── HP yang navigasi — Watch tampil sebagai mirror ──
                WatchPhoneMirrorView(navData: phoneData) {
                    session.takeOverFromPhone()
                }

            } else {
                // ── Idle ──
                WatchIdleView(onStartStandalone: {
                    session.showLocationPicker = true
                })
                .sheet(isPresented: $session.showLocationPicker) {
                    WatchLocationPickerView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.isNavigating)
        .animation(.easeInOut(duration: 0.3), value: session.navigationOwner)
    }
}

// MARK: - WatchPhoneMirrorView

/// Tampil di Watch saat HP yang sedang navigasi.
/// Menampilkan info ringkas + satu tombol besar untuk ambil alih.
private struct WatchPhoneMirrorView: View {
    let navData: WatchNavData
    let onTakeOver: () -> Void

    private var destination: WatchLocation? {
        guard navData.destinationIndex < navData.locations.count else { return nil }
        return navData.locations[navData.destinationIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon iPhone
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 46, height: 46)
                Image(systemName: "iphone")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.bottom, 10)

            // Nama tujuan
            Text(destination?.name ?? "Navigasi")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 16)

            // Label status
            Text("Berjalan di iPhone")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 3)
                .padding(.bottom, 14)

            // Tombol ambil alih
            Button {
                onTakeOver()
            } label: {
                Text("Lanjutkan di sini")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.35, green: 0.95, blue: 0.55))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - WatchIdleView

private struct WatchIdleView: View {
    var onStartStandalone: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "location.north.line.fill")
                .font(.system(size: 34))
                .foregroundColor(.white.opacity(0.35))

            Text("Navee")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)

            Text("Mulai dari iPhone\natau pilih lokasi")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)

            Button {
                onStartStandalone()
            } label: {
                Label("Pilih Lokasi", systemImage: "mappin.and.ellipse")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.15))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - WatchLocationPickerView

struct WatchLocationPickerView: View {
    @StateObject private var session = WatchSessionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if session.savedLocations.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Belum ada lokasi tersimpan")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                        Text("Buka Navee di iPhone untuk menyimpan lokasi.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(session.savedLocations) { location in
                        Button {
                            session.startStandaloneNavigation(to: location)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: location.emoji)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(location.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                    if !location.notes.isEmpty {
                                        Text(location.notes)
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.4))
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pilih Tujuan")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
