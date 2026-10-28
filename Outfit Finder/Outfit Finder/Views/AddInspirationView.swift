import SwiftUI
import SwiftData
import PhotosUI

/// Adds an outfit photo, detects its pieces, and lets the user correct them.
struct AddInspirationView: View {
    /// A piece being reviewed before the look is saved.
    struct PieceDraft: Identifiable {
        let id = UUID()
        var category: Category
        var colorFamily: ColorFamily
        var colorName: String
        var details: String

        var label: String {
            InspirationPiece.label(category: category, colorName: colorName, details: details)
        }
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var folder: InspirationFolder?
    @State private var imageData: Data?
    @State private var drafts: [PieceDraft] = []
    @State private var libraryPhoto: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var isAnalyzing = false
    @State private var analysisMessage: String?

    /// `folder` preselects where the look is saved, when adding from inside one.
    init(folder: InspirationFolder? = nil) {
        _folder = State(initialValue: folder)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let imageData {
                        PhotoView(data: imageData, placeholderSymbol: "photo")
                            .frame(height: 320)
                            .frame(maxWidth: .infinity)
                    }
                    if CameraPicker.isAvailable {
                        Button("Take Photo", systemImage: "camera") { isShowingCamera = true }
                    }
                    PhotosPicker(selection: $libraryPhoto, matching: .images) {
                        Label(imageData == nil ? "Choose Outfit Photo" : "Choose a Different Photo",
                              systemImage: "photo.on.rectangle")
                    }
                } footer: {
                    if imageData == nil {
                        Text("Pick a photo of a complete outfit you'd like to recreate.")
                    }
                }

                if imageData != nil {
                    Section {
                        TextField("Name, e.g. Weekend layers", text: $title)
                        FolderPicker(selection: $folder)
                    }
                    piecesSection
                }
            }
            .navigationTitle("New Inspiration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(imageData == nil || isAnalyzing)
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker { image in
                    Task { await photoChosen(image.downscaledJPEG()) }
                }
                .ignoresSafeArea()
            }
            .task(id: libraryPhoto) {
                guard let libraryPhoto,
                      let data = try? await libraryPhoto.loadTransferable(type: Data.self)
                else { return }
                await photoChosen(UIImage(data: data)?.downscaledJPEG())
            }
        }
    }

    @ViewBuilder
    private var piecesSection: some View {
        Section {
            if isAnalyzing {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Detecting pieces…").foregroundStyle(.secondary)
                }
            }
            ForEach($drafts) { $draft in
                NavigationLink {
                    Form {
                        PieceFields(
                            category: $draft.category,
                            colorFamily: $draft.colorFamily,
                            colorName: $draft.colorName,
                            details: $draft.details
                        )
                    }
                    .navigationTitle("Edit Piece")
                } label: {
                    PieceRow(category: draft.category, colorFamily: draft.colorFamily, label: draft.label)
                }
            }
            .onDelete { drafts.remove(atOffsets: $0) }

            Button("Add Piece", systemImage: "plus") {
                drafts.append(PieceDraft(category: .top, colorFamily: .unknown, colorName: "", details: ""))
            }
            if !isAnalyzing, imageData != nil, !KeychainStore.apiKey.isEmpty {
                Button("Detect Pieces Again", systemImage: "sparkles") {
                    Task { await analyze() }
                }
            }
        } header: {
            Text("Pieces")
        } footer: {
            if let analysisMessage {
                Text(analysisMessage)
            } else if !drafts.isEmpty {
                Text("Tap a piece to fix its type or colour. Recommendations match on these.")
            }
        }
    }

    private func photoChosen(_ data: Data?) async {
        guard let data else { return }
        imageData = data
        drafts = []
        await analyze()
    }

    private func analyze() async {
        guard let imageData else { return }
        let apiKey = KeychainStore.apiKey
        guard !apiKey.isEmpty else {
            analysisMessage = "Add an Anthropic API key in settings to detect pieces automatically, or add them yourself."
            return
        }

        isAnalyzing = true
        analysisMessage = nil
        defer { isAnalyzing = false }
        do {
            let analysis = try await ClaudeStylist(apiKey: apiKey).analyzeLook(jpeg: imageData)
            drafts = analysis.pieces.map { piece in
                PieceDraft(
                    category: Category(rawValue: piece.category) ?? .other,
                    colorFamily: ColorFamily(rawValue: piece.colorFamily) ?? .unknown,
                    colorName: piece.colorName,
                    details: piece.description
                )
            }
            if title.isEmpty { title = analysis.title }
            if drafts.isEmpty { analysisMessage = "No clothing found in this photo." }
        } catch {
            analysisMessage = error.localizedDescription
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let look = InspirationLook(title: trimmed.isEmpty ? "Inspiration" : trimmed, imageData: imageData, folder: folder)
        context.insert(look)
        for (position, draft) in drafts.enumerated() {
            let piece = InspirationPiece(
                category: draft.category,
                colorFamily: draft.colorFamily,
                colorName: draft.colorName.trimmingCharacters(in: .whitespaces),
                details: draft.details.trimmingCharacters(in: .whitespaces),
                position: position
            )
            context.insert(piece)
            piece.look = look
        }
        dismiss()
    }
}
