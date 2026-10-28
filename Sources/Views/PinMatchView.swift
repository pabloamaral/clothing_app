import SwiftUI
import SwiftData

/// One pin, and Claude's take on how to recreate it from the closet.
struct PinMatchView: View {
    /// Caps the request size: each thumbnail costs input tokens.
    private static let maxClosetItems = 60

    let pin: InspirationPin

    @Environment(\.modelContext) private var context
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var closet: [ClothingItem]

    @State private var match: LookMatch?
    @State private var matchedItems: [ClothingItem] = []
    @State private var isMatching = false
    @State private var errorMessage: String?
    @State private var isSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PinImage(url: pin.imageURL)
                    .frame(height: 380)
                    .clipShape(.rect(cornerRadius: 16))

                if let match {
                    result(match)
                } else if isMatching {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Looking through your closet…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Button(action: { Task { await findMatches() } }) {
                        Label("Find in My Closet", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(closet.isEmpty)

                    if closet.isEmpty {
                        Text("Add some clothes to your closet first.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Recreate This Look")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func result(_ match: LookMatch) -> some View {
        Text(match.lookDescription)
            .font(.headline)

        if matchedItems.isEmpty {
            Text("Nothing in your closet is a close match yet.")
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("From your closet")
                    .font(.subheadline.weight(.semibold))
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(matchedItems) { item in
                            VStack(spacing: 4) {
                                ItemImage(item: item, cornerRadius: 10)
                                    .frame(width: 96, height: 96)
                                Text(item.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(width: 96)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            Label(match.stylingTip, systemImage: "lightbulb")
                .font(.subheadline)
        }

        if !match.missingPieces.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("To complete the look")
                    .font(.subheadline.weight(.semibold))
                ForEach(match.missingPieces, id: \.self) { piece in
                    Label(piece, systemImage: "bag")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }

        if !matchedItems.isEmpty {
            Button(isSaved ? "Saved to Outfits" : "Save as Outfit",
                   systemImage: isSaved ? "checkmark" : "plus") {
                save(match)
            }
            .buttonStyle(.bordered)
            .disabled(isSaved)
        }
    }

    private func findMatches() async {
        isMatching = true
        errorMessage = nil
        defer { isMatching = false }

        let items = Array(closet.prefix(Self.maxClosetItems))
        // SwiftData models must stay on the main actor, so only the raw photo
        // bytes go to the background to be shrunk.
        let photos = items.map(\.imageData)
        let thumbnails = await Task.detached(priority: .userInitiated) {
            photos.map { data in
                data.flatMap { UIImage(data: $0)?.downscaledJPEG(maxDimension: 384, quality: 0.7) }
            }
        }.value

        let entries = items.enumerated().map { index, item in
            ClosetEntry(
                index: index,
                name: item.name,
                category: item.category.label,
                color: colorDescription(item),
                notes: item.notes,
                jpeg: thumbnails[index]
            )
        }

        do {
            let result = try await ClaudeStylist(apiKey: KeychainStore.apiKey)
                .match(pinImageURL: pin.imageURL, closet: entries)
            matchedItems = result.matchedItemIndices.map { items[$0] }
            match = result
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func colorDescription(_ item: ClothingItem) -> String {
        let family = item.colorFamily == .unknown ? "" : item.colorFamily.label
        switch (family.isEmpty, item.colorName.isEmpty) {
        case (false, false): return "\(item.colorName) (\(family))"
        case (false, true): return family
        case (true, false): return item.colorName
        case (true, true): return ""
        }
    }

    private func save(_ match: LookMatch) {
        let name = String(match.lookDescription.prefix(40))
        context.insert(Outfit(name: name, notes: match.stylingTip, items: matchedItems))
        isSaved = true
    }
}
