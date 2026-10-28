import SwiftUI
import SwiftData

/// Creates a new outfit, or edits an existing one when `outfit` is non-nil.
struct OutfitBuilderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ClothingItem.name) private var allItems: [ClothingItem]

    let outfit: Outfit?

    @State private var name = ""
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var hasLoaded = false

    private var isEditing: Bool { outfit != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedIDs.isEmpty
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("e.g. Rainy Monday", text: $name)
            }

            ForEach(Category.allCases) { category in
                let categoryItems = allItems.filter { $0.category == category }
                if !categoryItems.isEmpty {
                    Section(category.label) {
                        ForEach(categoryItems) { item in
                            SelectableItemRow(
                                item: item,
                                isSelected: selectedIDs.contains(item.persistentModelID)
                            ) {
                                toggle(item)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Outfit" : "New Outfit")
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
            }
        }
        .onAppear(perform: loadExisting)
    }

    private func loadExisting() {
        guard !hasLoaded, let outfit else { return }
        name = outfit.name
        selectedIDs = Set(outfit.items.map(\.persistentModelID))
        hasLoaded = true
    }

    private func toggle(_ item: ClothingItem) {
        let id = item.persistentModelID
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func save() {
        let chosen = allItems.filter { selectedIDs.contains($0.persistentModelID) }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if let outfit {
            outfit.name = trimmedName
            outfit.items = chosen
        } else {
            context.insert(Outfit(name: trimmedName, items: chosen))
        }
        dismiss()
    }
}

private struct SelectableItemRow: View {
    let item: ClothingItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                ItemImage(item: item, cornerRadius: 6)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text(item.name)
                    if !item.colorName.isEmpty {
                        Text(item.colorName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
        }
        .buttonStyle(.plain)
    }
}
