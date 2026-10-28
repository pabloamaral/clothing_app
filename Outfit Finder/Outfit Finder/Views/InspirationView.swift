import SwiftUI
import SwiftData

/// What a folder tile opens: a real folder, or the looks that aren't in one.
enum InspirationGroup: Hashable {
    case folder(InspirationFolder)
    case unfiled
}

/// The user's inspiration folders, shown as a grid of cover photos.
struct InspirationView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \InspirationFolder.name) private var folders: [InspirationFolder]
    @Query(filter: #Predicate<InspirationLook> { $0.folder == nil },
           sort: \InspirationLook.createdAt, order: .reverse)
    private var unfiled: [InspirationLook]

    @State private var isAdding = false
    @State private var isShowingSettings = false
    @State private var isNamingFolder = false
    @State private var newFolderName = ""

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            Group {
                if folders.isEmpty && unfiled.isEmpty {
                    ContentUnavailableView {
                        Label("No inspiration yet", systemImage: "photo.stack")
                    } description: {
                        Text("Make folders for the kinds of outfits you love, like Work or Date night, then add photos to them. The app notes each piece and finds the closest matches in your closet.")
                    } actions: {
                        Button("New Folder") { isNamingFolder = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(folders) { folder in
                                NavigationLink(value: InspirationGroup.folder(folder)) {
                                    FolderTile(
                                        name: folder.name,
                                        cover: folder.sortedLooks.first?.imageData,
                                        count: folder.looks.count,
                                        symbol: "folder"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            if !unfiled.isEmpty {
                                NavigationLink(value: InspirationGroup.unfiled) {
                                    FolderTile(name: "Unfiled", cover: unfiled.first?.imageData,
                                               count: unfiled.count, symbol: "tray")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Inspiration")
            .navigationDestination(for: InspirationGroup.self) { InspirationFolderView(group: $0) }
            .navigationDestination(for: InspirationLook.self) { InspirationDetailView(look: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { isShowingSettings = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu("Add", systemImage: "plus") {
                        Button("New Folder", systemImage: "folder.badge.plus") { isNamingFolder = true }
                        Button("Add Photo", systemImage: "photo.badge.plus") { isAdding = true }
                    }
                }
            }
            .sheet(isPresented: $isAdding) { AddInspirationView() }
            .sheet(isPresented: $isShowingSettings) { APIKeySettingsView() }
            .alert("New Folder", isPresented: $isNamingFolder) {
                TextField("e.g. Date night", text: $newFolderName)
                Button("Create", action: createFolder)
                Button("Cancel", role: .cancel) { newFolderName = "" }
            }
        }
    }

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespaces)
        newFolderName = ""
        guard !name.isEmpty else { return }
        context.insert(InspirationFolder(name: name))
    }
}

/// A folder's cover photo with its name and photo count underneath.
private struct FolderTile: View {
    let name: String
    let cover: Data?
    let count: Int
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PhotoView(data: cover, placeholderSymbol: symbol)
                .aspectRatio(3 / 4, contentMode: .fit)

            Text(name)
                .font(.headline)
                .lineLimit(1)
            Text(count == 1 ? "1 photo" : "\(count) photos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
