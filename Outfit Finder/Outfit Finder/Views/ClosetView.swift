import SwiftUI
import SwiftData

/// Grid of every garment the user owns, filterable by category.
struct ClosetView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var items: [ClothingItem]

    @State private var isAddingItem = false
    @State private var selectedCategory: Category?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    private var visibleItems: [ClothingItem] {
        guard let selectedCategory else { return items }
        return items.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Your closet is empty",
                        systemImage: "tshirt",
                        description: Text("Tap + to photograph your first garment.")
                    )
                } else {
                    ScrollView {
                        categoryFilter

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(visibleItems) { item in
                                NavigationLink(value: item) {
                                    ItemCell(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Closet")
            .navigationDestination(for: ClothingItem.self) { ItemDetailView(item: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Item", systemImage: "plus") { isAddingItem = true }
                }
            }
            .sheet(isPresented: $isAddingItem) {
                AddItemView()
            }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isOn: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(Category.allCases) { category in
                    FilterChip(title: category.label, isOn: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, 4)
    }
}

private struct ItemCell: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ItemImage(item: item)
                .aspectRatio(1, contentMode: .fit)

            Text(item.name)
                .font(.subheadline)
                .lineLimit(1)

            Text(item.colorName.isEmpty ? item.category.label : item.colorName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
            .foregroundStyle(isOn ? .white : .primary)
            .clipShape(.capsule)
    }
}
