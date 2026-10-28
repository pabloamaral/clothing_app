import SwiftUI
import SwiftData
import PhotosUI

/// Form for adding a garment to the closet.
struct AddItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: Category = .top
    @State private var colorFamily: ColorFamily = .unknown
    @State private var colorName = ""
    @State private var notes = ""
    @State private var libraryPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isShowingCamera = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    photoPreview

                    if CameraPicker.isAvailable {
                        Button("Take Photo", systemImage: "camera") {
                            isShowingCamera = true
                        }
                    }
                    PhotosPicker(selection: $libraryPhoto, matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                }

                Section("Details") {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section {
                    Picker("Colour", selection: $colorFamily) {
                        ForEach(ColorFamily.allCases) { Text($0.label).tag($0) }
                    }
                    TextField("Colour name (optional)", text: $colorName)
                } header: {
                    Text("Colour")
                } footer: {
                    Text("Used to suggest what to pair this with.")
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker { image in
                    imageData = image.downscaledJPEG()
                }
                .ignoresSafeArea()
            }
            // Loading the picked photo's bytes is async, so it happens here
            // rather than inline in the picker.
            .task(id: libraryPhoto) {
                guard let libraryPhoto,
                      let data = try? await libraryPhoto.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else { return }
                imageData = image.downscaledJPEG()
            }
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(.rect(cornerRadius: 12))
        } else {
            Image(systemName: category.symbol)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
        }
    }

    private func save() {
        let item = ClothingItem(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            colorName: colorName.trimmingCharacters(in: .whitespaces),
            colorFamily: colorFamily,
            notes: notes,
            imageData: imageData
        )
        context.insert(item)
        dismiss()
    }
}
