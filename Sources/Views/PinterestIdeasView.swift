import SwiftUI

/// Grid of pins from the user's chosen Pinterest board.
struct PinterestIdeasView: View {
    let openSettings: () -> Void

    @AppStorage("pinterestBoardLink") private var boardLink = ""
    @State private var pins: [InspirationPin] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 8)]

    var body: some View {
        Group {
            if boardLink.isEmpty {
                ContentUnavailableView {
                    Label("Connect a board", systemImage: "pin")
                } description: {
                    Text("Paste a link to a public Pinterest board of outfits you like, then tap a pin to recreate it from your closet.")
                } actions: {
                    Button("Add Board", action: openSettings)
                        .buttonStyle(.borderedProminent)
                }
            } else if let errorMessage, pins.isEmpty {
                ContentUnavailableView {
                    Label("Couldn't load board", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again") { Task { await load() } }
                    Button("Change Board", action: openSettings)
                }
            } else if isLoading && pins.isEmpty {
                ProgressView("Loading pins…")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(pins) { pin in
                            NavigationLink(value: pin) {
                                PinImage(url: pin.imageURL)
                                    .frame(height: 220)
                                    .clipShape(.rect(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .refreshable { await load() }
            }
        }
        .navigationDestination(for: InspirationPin.self) { PinMatchView(pin: $0) }
        .task(id: boardLink) { await load() }
    }

    private func load() async {
        guard !boardLink.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            pins = try await PinterestBoard.fetchPins(fromLink: boardLink)
            errorMessage = nil
        } catch {
            pins = []
            errorMessage = error.localizedDescription
        }
    }
}

/// A remote pin image that fills its frame, with a placeholder while loading.
struct PinImage: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Rectangle().fill(.quaternary)
                    .overlay { Image(systemName: "photo").foregroundStyle(.secondary) }
            default:
                Rectangle().fill(.quaternary)
                    .overlay { ProgressView() }
            }
        }
        // Without this, scaledToFill lets wide images spill outside the grid cell.
        .frame(maxWidth: .infinity)
        .clipped()
    }
}
