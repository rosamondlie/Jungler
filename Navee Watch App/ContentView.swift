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
                // Navigasi aktif — dari iPhone atau dimulai dari Watch langsung
                WatchNavigationView(
                    allLocations: session.watchLocations,
                    destinationIndex: session.destinationIndex,
                    onEndNavigation: {
                        withAnimation { session.isNavigating = false }
                    }
                )
            } else {
                WatchIdleView(onStartStandalone: {
                    // User mau pilih destinasi dari Watch sendiri
                    session.showLocationPicker = true
                })
                .sheet(isPresented: $session.showLocationPicker) {
                    WatchLocationPickerView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.isNavigating)
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
// Menampilkan lokasi yang sudah tersimpan di Watch (dikirim dari iPhone sebelumnya)

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
