import SwiftUI

/// Shows a stored photo, or a symbol when there is no photo.
struct PhotoView: View {
    let data: Data?
    let placeholderSymbol: String
    var cornerRadius: CGFloat = 12

    var body: some View {
        // The rectangle takes whatever size the caller gives; the photo fills
        // it and is cropped, so it can never spill out of a grid cell.
        Rectangle()
            .fill(.quaternary)
            .overlay {
                if let data, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: placeholderSymbol)
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
    }
}

/// Shows a garment's photo, or its category symbol when there is no photo yet.
struct ItemImage: View {
    let item: ClothingItem
    var cornerRadius: CGFloat = 12

    var body: some View {
        PhotoView(data: item.imageData, placeholderSymbol: item.category.symbol, cornerRadius: cornerRadius)
    }
}
