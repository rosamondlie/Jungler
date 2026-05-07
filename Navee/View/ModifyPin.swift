//
//  ModifyPin.swift
//  Navee
//

import SwiftUI
import CoreLocation

struct ModifyPin: View {
    @Binding var location: Location
    var userLocation: CLLocation?
    var onSave:   () -> Void
    var onDelete: () -> Void

    @State private var draft: Location

    private let nameLimit = 20

    init(
        location: Binding<Location>,
        userLocation: CLLocation?,
        onSave: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self._location    = location
        self.userLocation = userLocation
        self.onSave       = onSave
        self.onDelete     = onDelete
        self._draft       = State(initialValue: location.wrappedValue)
    }

    var body: some View {
        Form {
            nameSection
            iconSection
            infoSection
            deleteSection
        }
        .scrollContentBackground(.hidden)   // ← matikan background UITableView
        .background(Color.black)            // ← langsung hitam dari frame pertama
        .navigationTitle("Edit Point")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    location = draft
                    onSave()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(draft.name.isEmpty)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Name

    private var nameSection: some View {
        Section {
            HStack {
                TextField("Point name", text: Binding(
                    get: { draft.name },
                    set: { draft.name = String($0.prefix(nameLimit)) }
                ))
                Spacer()
                Text("\(draft.name.count)/\(nameLimit)")
                    .font(.caption)
                    .foregroundStyle(draft.name.count >= nameLimit ? .red : .secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        Section {
            IconPicker(selectedIcon: $draft.emoji)
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        Section {
            InfoRow(
                label: "Distance",
                value: draft.formattedDistance(from: userLocation, suffix: "away")
            )
            InfoRow(
                label: "Altitude",
                value: "\(Int(draft.altitude)) masl"
            )
            InfoRow(
                label: "Coordinates",
                value: String(
                    format: "%.4f, %.4f",
                    draft.coordinate.latitude,
                    draft.coordinate.longitude
                )
            )
            InfoRow(
                label: "Saved",
                value: draft.timestamp.relativeFormatted()
            )
        }
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Text("Delete Location")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModifyPin(
            location: .constant(Location(
                name:       "Point 1",
                coordinate: .init(latitude: -6.2, longitude: 106.8166),
                altitude:   12,
                emoji:      "flame.fill",
                notes:      ""
            )),
            userLocation: CLLocation(latitude: -6.2012, longitude: 106.8154),
            onSave:   {},
            onDelete: {}
        )
    }
    .preferredColorScheme(.dark)
}
