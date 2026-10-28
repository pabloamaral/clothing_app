import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: ClothingItem

    var body: some View {
        Form {
            Section {
                ItemImage(item: item)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }

            Section("Details") {
                TextField("Name", text: $item.name)
                Picker("Category", selection: $item.category) {
                    ForEach(Category.allCases) { Text($0.label).tag($0) }
                }
                Picker("Colour", selection: $item.colorFamily) {
                    ForEach(ColorFamily.allCases) { Text($0.label).tag($0) }
                }
                TextField("Colour name", text: $item.colorName)
            }

            if !item.outfits.isEmpty {
                Section("Worn in") {
                    ForEach(item.outfits) { outfit in
                        Text(outfit.name)
                    }
                }
            }

            Section {
                Button("Delete Item", role: .destructive) {
                    context.delete(item)
                    dismiss()
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
