import SwiftUI
import SwiftData

/// List of saved outfits.
struct OutfitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Outfit.createdAt, order: .reverse) private var outfits: [Outfit]
    @Query private var items: [ClothingItem]

    @State private var isBuilding = false

    var body: some View {
        NavigationStack {
            Group {
                if outfits.isEmpty {
                    ContentUnavailableView(
                        "No outfits yet",
                        systemImage: "hanger",
                        description: Text(items.isEmpty
                            ? "Add some clothes to your closet first."
                            : "Tap + to combine items into an outfit.")
                    )
                } else {
                    List {
                        ForEach(outfits) { outfit in
                            NavigationLink(value: outfit) {
                                OutfitRow(outfit: outfit)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Outfits")
            .navigationDestination(for: Outfit.self) { OutfitBuilderView(outfit: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Outfit", systemImage: "plus") { isBuilding = true }
                        .disabled(items.isEmpty)
                }
            }
            .sheet(isPresented: $isBuilding) {
                NavigationStack {
                    OutfitBuilderView(outfit: nil)
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(outfits[index])
        }
    }
}

private struct OutfitRow: View {
    let outfit: Outfit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(outfit.name)
                .font(.headline)

            HStack(spacing: 6) {
                ForEach(outfit.items.prefix(5)) { item in
                    ItemImage(item: item, cornerRadius: 6)
                        .frame(width: 44, height: 44)
                }
                if outfit.items.count > 5 {
                    Text("+\(outfit.items.count - 5)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
