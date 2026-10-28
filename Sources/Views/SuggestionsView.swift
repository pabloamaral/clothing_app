import SwiftUI
import SwiftData

/// Outfit ideas generated from the closet, each savable as a real outfit.
/// Shown inside `IdeasView`, which supplies the navigation stack.
struct SuggestionsView: View {
    @Environment(\.modelContext) private var context
    @Query private var closet: [ClothingItem]

    @State private var savedIDs: Set<[ObjectIdentifier]> = []

    private var suggestions: [OutfitSuggestion] {
        OutfitRecommender.suggestions(from: closet)
    }

    var body: some View {
        if suggestions.isEmpty {
            ContentUnavailableView(
                "No ideas yet",
                systemImage: "sparkles",
                description: Text("Add at least one top and one bottom, or a dress, and tag their colours.")
            )
        } else {
            List(suggestions) { suggestion in
                SuggestionRow(
                    suggestion: suggestion,
                    isSaved: savedIDs.contains(suggestion.id)
                ) {
                    save(suggestion)
                }
            }
        }
    }

    private func save(_ suggestion: OutfitSuggestion) {
        let name = suggestion.items.map(\.name).joined(separator: " + ")
        context.insert(Outfit(name: name, items: suggestion.items))
        savedIDs.insert(suggestion.id)
    }
}

private struct SuggestionRow: View {
    let suggestion: OutfitSuggestion
    let isSaved: Bool
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(suggestion.items) { item in
                    VStack(spacing: 4) {
                        ItemImage(item: item, cornerRadius: 8)
                            .frame(width: 64, height: 64)
                        Text(item.name)
                            .font(.caption2)
                            .lineLimit(1)
                            .frame(width: 64)
                    }
                }
            }

            HStack {
                Label(suggestion.reason, systemImage: "sparkles")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(isSaved ? "Saved" : "Save", systemImage: isSaved ? "checkmark" : "plus") {
                    onSave()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isSaved)
            }
        }
        .padding(.vertical, 4)
    }
}
