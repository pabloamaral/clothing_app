import SwiftUI

/// Shows a garment's photo, or a category symbol when there is no photo yet.
struct ItemImage: View {
    let item: ClothingItem
    var cornerRadius: CGFloat = 12

    var body: some View {
        ZStack {
            if let data = item.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: item.category.symbol)
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
    }
}
