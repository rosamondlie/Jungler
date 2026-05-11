// ModifyPin.swift

import SwiftUI
import SwiftData
import CoreLocation

struct ModifyPin: View {

    // Langsung terima object SwiftData — tidak perlu @Binding
    var location: Location
    var userLocation: CLLocation?
    var onSave:   () -> Void
    var onDelete: () -> Void

    @Environment(\.modelContext) private var context

    // Draft lokal untuk edit nama & emoji sebelum di-save
    @State private var draftName:  String
    @State private var draftEmoji: String
    @State private var showDeleteAlert = false

    private let nameLimit = 20

    init(
        location: Location,
        userLocation: CLLocation?,
        onSave: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.location     = location
        self.userLocation = userLocation
        self.onSave       = onSave
        self.onDelete     = onDelete
        self._draftName   = State(initialValue: location.name)
        self._draftEmoji  = State(initialValue: location.emoji)
    }

    var body: some View {
        List {
            nameSection
            IconPickerSection(selectedIcon: $draftEmoji)
            infoSection
            deleteSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle("Edit Point")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    // Tulis perubahan ke SwiftData object
                    location.name  = draftName
                    location.emoji = draftEmoji
                    // SwiftData auto-save — tidak perlu context.save()
                    onSave()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Delete Location?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        Section {
            HStack {
                TextField("Point name", text: $draftName)
                    .onChange(of: draftName) { _, new in
                        if new.count > nameLimit {
                            draftName = String(new.prefix(nameLimit))
                        }
                    }
                Spacer()
                Text("\(min(draftName.count, nameLimit))/\(nameLimit)")
                    .font(.caption)
                    .foregroundStyle(draftName.count >= nameLimit ? .red : .secondary)
                    .monospacedDigit()
                    .animation(.none, value: draftName.count)
            }
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        Section {
            InfoRow(label: "Distance",    value: location.formattedDistance(from: userLocation, suffix: "away"))
            InfoRow(label: "Altitude",    value: "\(Int(location.altitude)) masl")
            InfoRow(label: "Coordinates", value: String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude))
            InfoRow(label: "Saved",       value: location.timestamp.relativeFormatted())
        }
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Text("Delete Location")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - IconPickerSection (tidak berubah)

private struct IconPickerSection: View {
    @Binding var selectedIcon: String
    @State private var scrollOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var viewWidth:    CGFloat = 0

    private var showLeftFade:  Bool { scrollOffset > 8 }
    private var showRightFade: Bool { scrollOffset < contentWidth - viewWidth - 8 }

    var body: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                IconPicker(selectedIcon: $selectedIcon)
                    .padding(.leading, 2)
                    .padding(.trailing, 32)
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear { contentWidth = geo.size.width }
                        }
                    )
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.x
            } action: { _, new in
                scrollOffset = new
            }
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear { viewWidth = geo.size.width }
                }
            )
            .overlay(alignment: .leading) {
                if showLeftFade {
                    fadeMask(direction: .leading).transition(.opacity)
                }
            }
            .overlay(alignment: .trailing) {
                fadeMask(direction: .trailing).opacity(showRightFade ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.2), value: showLeftFade)
            .animation(.easeInOut(duration: 0.2), value: showRightFade)
        }
    }

    private func fadeMask(direction: UnitPoint) -> some View {
        LinearGradient(
            colors: [Color(UIColor.secondarySystemGroupedBackground), .clear],
            startPoint: direction,
            endPoint: direction == .leading ? .trailing : .leading
        )
        .frame(width: 56)
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    // Preview tidak bisa pakai @Model tanpa container
    // Buat in-memory container khusus preview
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Location.self, configurations: config)
    let sample    = Location(
        name:       "Point 1",
        coordinate: .init(latitude: -6.2, longitude: 106.8166),
        altitude:   12,
        emoji:      "flame.fill"
    )
    container.mainContext.insert(sample)

    return NavigationStack {
        ModifyPin(
            location:     sample,
            userLocation: CLLocation(latitude: -6.2012, longitude: 106.8154),
            onSave:       {},
            onDelete:     {}
        )
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
