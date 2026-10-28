import SwiftUI
import SwiftData

/// The looks inside one folder, or the unfiled ones.
struct InspirationFolderView: View {
    let group: InspirationGroup

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<InspirationLook> { $0.folder == nil },
           sort: \InspirationLook.createdAt, order: .reverse)
    private var unfiled: [InspirationLook]
    @Query private var closet: [ClothingItem]

    @State private var isAdding = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isConfirmingDelete = false

    private var folder: InspirationFolder? {
        if case .folder(let folder) = group { folder } else { nil }
    }

    private var looks: [InspirationLook] {
        folder?.sortedLooks ?? unfiled
    }

    var body: some View {
        let looks = self.looks

        Group {
            if looks.isEmpty {
                ContentUnavailableView {
                    Label("No photos yet", systemImage: "photo.on.rectangle")
                } description: {
                    Text("Add photos of outfits that belong in this folder.")
                } actions: {
                    Button("Add Photo") { isAdding = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(looks) { look in
                        NavigationLink(value: look) {
                            InspirationRow(look: look, closet: closet)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { context.delete(looks[index]) }
                    }
                }
            }
        }
        .navigationTitle(folder?.name ?? "Unfiled")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Photo", systemImage: "plus") { isAdding = true }
            }
            if folder != nil {
                ToolbarItem(placement: .secondaryAction) {
                    Button("Rename Folder", systemImage: "pencil") {
                        renameText = folder?.name ?? ""
                        isRenaming = true
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Delete Folder", systemImage: "trash", role: .destructive) {
                        isConfirmingDelete = true
                    }
                }
            }
        }
        .sheet(isPresented: $isAdding) { AddInspirationView(folder: folder) }
        .alert("Rename Folder", isPresented: $isRenaming) {
            TextField("Name", text: $renameText)
            Button("Save") {
                let name = renameText.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { folder?.name = name }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete “\(folder?.name ?? "")”?", isPresented: $isConfirmingDelete,
                            titleVisibility: .visible) {
            Button("Delete Folder, Keep Photos") { deleteFolder(includingPhotos: false) }
            if !looks.isEmpty {
                Button("Delete Folder and \(looks.count == 1 ? "1 Photo" : "\(looks.count) Photos")",
                       role: .destructive) {
                    deleteFolder(includingPhotos: true)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Kept photos move to Unfiled.")
        }
    }

    private func deleteFolder(includingPhotos: Bool) {
        guard let folder else { return }
        // Leave the screen before the folder it shows is deleted.
        dismiss()
        if includingPhotos {
            for look in folder.looks { context.delete(look) }
        }
        context.delete(folder)
    }
}

/// One saved look: its photo, pieces, and how much of it the closet covers.
struct InspirationRow: View {
    let look: InspirationLook
    let closet: [ClothingItem]

    var body: some View {
        let pieces = look.orderedPieces
        let matched = InspirationMatcher.recreate(pieces, from: closet).compactMap(\.candidates.first?.item)

        HStack(spacing: 12) {
            PhotoView(data: look.imageData, placeholderSymbol: "photo", cornerRadius: 8)
                .frame(width: 64, height: 84)

            VStack(alignment: .leading, spacing: 6) {
                Text(look.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(pieces.map(\.label).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if !pieces.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(matched.prefix(4)) { item in
                            ItemImage(item: item, cornerRadius: 4)
                                .frame(width: 24, height: 24)
                        }
                        Text("\(matched.count) of \(pieces.count) in your closet")
                            .font(.caption2)
                            .foregroundStyle(matched.count == pieces.count ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Picks which folder a look lives in, or none.
struct FolderPicker: View {
    @Binding var selection: InspirationFolder?
    @Query(sort: \InspirationFolder.name) private var folders: [InspirationFolder]

    var body: some View {
        if !folders.isEmpty {
            Picker("Folder", selection: $selection) {
                Text("None").tag(InspirationFolder?.none)
                ForEach(folders) { folder in
                    Text(folder.name).tag(Optional(folder))
                }
            }
        }
    }
}
