import SwiftUI
import CoreLocation

struct ModifyPin: View {
    @Environment(\.dismiss) var dismiss

    @Binding var location: Location
    var userLocation: CLLocation?
    var onDelete: () -> Void

    @State private var draft: Location

    init(location: Binding<Location>, userLocation: CLLocation?, onDelete: @escaping () -> Void) {
        self._location = location
        self.userLocation = userLocation
        self.onDelete = onDelete
        self._draft = State(initialValue: location.wrappedValue)
    }

    private var limitedNameBinding: Binding<String> {
        Binding(
            get: { draft.name },
            set: { newValue in
                let truncated = String(newValue.prefix(20))
                if draft.name != truncated {
                    draft.name = truncated
                }
            }
        )
    }

    var body: some View {
        Form {
            nameSection
            iconSection
            infoSection
            deleteSection
        }
        .navigationTitle("Edit Point")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                doneButton
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            HStack {
                TextField("Point name", text: limitedNameBinding)
                    .onChange(of: draft.name) { _, newValue in
                        let truncated = String(newValue.prefix(20))
                        if newValue != truncated {
                            draft.name = truncated
                        }
                    }

                Spacer()

                Text("\(draft.name.count)/20")
                    .font(.caption)
                    .foregroundStyle(draft.name.count >= 20 ? .red : .secondary)
                    .monospacedDigit()
            }
        }
    }

    private var iconSection: some View {
        Section {
            IconPicker(selectedIcon: $draft.emoji)
        }
    }

    private var infoSection: some View {
        Section {
            InfoRow(
                label: "Distance",
                value: draft.formattedDistance(from: userLocation, suffix: "away")
            )
            InfoRow(label: "Altitude",    value: "\(Int(draft.altitude)) mdpl")
            InfoRow(label: "Coordinates", value: String(
                format: "%.4f, %.4f",
                draft.coordinate.latitude,
                draft.coordinate.longitude
            ))
            InfoRow(label: "Saved", value: draft.timestamp.relativeFormatted())
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                onDelete()
                dismiss()
            } label: {
                Text("Delete Location")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var doneButton: some View {
        Button {
            location = draft  // ✅ baru save ke parent di sini
            dismiss()
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .disabled(draft.name.isEmpty)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModifyPin(
            location: .constant(Location(
                name: "Point 1",
                coordinate: .init(latitude: -6.2, longitude: 106.8166),
                altitude: 12,
                emoji: "flame.fill",
                notes: ""
            )),
            userLocation: CLLocation(latitude: -6.2012, longitude: 106.8154),
            onDelete: {}
        )
    }
    .preferredColorScheme(.dark)
}
