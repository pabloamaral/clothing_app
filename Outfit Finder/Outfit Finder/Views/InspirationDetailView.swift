import SwiftUI
import SwiftData

/// One inspiration look: how to recreate it from the closet, and its pieces.
struct InspirationDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var look: InspirationLook
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var closet: [ClothingItem]

    /// Alternatives the user tapped, keyed by the piece they replace.
    @State private var swaps: [PersistentIdentifier: PersistentIdentifier] = [:]
    @State private var isSaved = false

    var body: some View {
        let pieces = look.orderedPieces
        let matches = InspirationMatcher.recreate(pieces, from: closet)
        let chosenItems = matches.compactMap { chosen(for: $0)?.item }

        List {
            Section {
                PhotoView(data: look.imageData, placeholderSymbol: "photo", cornerRadius: 0)
                    .frame(height: 360)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                if matches.isEmpty {
                    Text("Add the pieces in this look below to get recommendations.")
                        .foregroundStyle(.secondary)
                }
                ForEach(matches, id: \.piece.persistentModelID) { match in
                    MatchRow(match: match, chosen: chosen(for: match)) { item in
                        swaps[match.piece.persistentModelID] = item.persistentModelID
                        isSaved = false
                    }
                }
            } header: {
                Text("From your closet")
            } footer: {
                if !matches.isEmpty {
                    Text("\(chosenItems.count) of \(matches.count) pieces covered. Tap another option to swap it in.")
                }
            }

            if !chosenItems.isEmpty {
                Section {
                    Button(isSaved ? "Saved to Outfits" : "Save as Outfit",
                           systemImage: isSaved ? "checkmark" : "plus") {
                        context.insert(Outfit(name: look.title, notes: "Inspired by \(look.title)", items: chosenItems))
                        isSaved = true
                    }
                    .disabled(isSaved)
                }
            }

            Section {
                TextField("Name", text: $look.title)
                FolderPicker(selection: $look.folder)
            }

            Section("Pieces in this look") {
                ForEach(pieces) { piece in
                    NavigationLink {
                        PieceEditView(piece: piece)
                    } label: {
                        PieceRow(category: piece.category, colorFamily: piece.colorFamily, label: piece.label)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(pieces[index]) }
                }
                Button("Add Piece", systemImage: "plus", action: addPiece)
            }

            Section {
                Button("Delete Inspiration", role: .destructive) {
                    dismiss()
                    context.delete(look)
                }
            }
        }
        .navigationTitle(look.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func chosen(for match: PieceMatch) -> (item: ClothingItem, quality: MatchQuality)? {
        if let swapID = swaps[match.piece.persistentModelID],
           let swapped = match.candidates.first(where: { $0.item.persistentModelID == swapID }) {
            return swapped
        }
        return match.candidates.first
    }

    private func addPiece() {
        let next = (look.pieces.map(\.position).max() ?? -1) + 1
        let piece = InspirationPiece(category: .top, colorFamily: .unknown, colorName: "", details: "", position: next)
        context.insert(piece)
        piece.look = look
    }
}

private struct MatchRow: View {
    let match: PieceMatch
    let chosen: (item: ClothingItem, quality: MatchQuality)?
    let onSwap: (ClothingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(match.piece.label, systemImage: match.piece.category.symbol)
                .font(.subheadline.weight(.semibold))

            if let chosen {
                HStack(spacing: 12) {
                    ItemImage(item: chosen.item, cornerRadius: 8)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(chosen.item.name)
                        Text(chosen.quality.label)
                            .font(.caption)
                            .foregroundStyle(color(for: chosen.quality))
                    }
                }

                if match.candidates.count > 1 {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(match.candidates, id: \.item.persistentModelID) { candidate in
                                let isChosen = candidate.item.persistentModelID == chosen.item.persistentModelID
                                Button { onSwap(candidate.item) } label: {
                                    ItemImage(item: candidate.item, cornerRadius: 6)
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(isChosen ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), lineWidth: 2)
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(candidate.item.name)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            } else {
                Label("Not in your closet yet", systemImage: "bag")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func color(for quality: MatchQuality) -> Color {
        switch quality {
        case .exact: .green
        case .close: .blue
        case .loose: .orange
        }
    }
}

private struct PieceEditView: View {
    @Bindable var piece: InspirationPiece

    var body: some View {
        Form {
            PieceFields(
                category: $piece.category,
                colorFamily: $piece.colorFamily,
                colorName: $piece.colorName,
                details: $piece.details
            )
        }
        .navigationTitle("Edit Piece")
    }
}
