import SwiftUI

/// Form rows for one inspiration piece, shared by the add and edit screens.
struct PieceFields: View {
    @Binding var category: Category
    @Binding var colorFamily: ColorFamily
    @Binding var colorName: String
    @Binding var details: String

    var body: some View {
        Picker("Type", selection: $category) {
            ForEach(Category.allCases) { Text($0.label).tag($0) }
        }
        Picker("Colour", selection: $colorFamily) {
            ForEach(ColorFamily.allCases) { Text($0.label).tag($0) }
        }
        TextField("Colour name, e.g. olive", text: $colorName)
        TextField("Description, e.g. wide-leg chinos", text: $details)
    }
}

/// A row summarizing one piece: its type icon, label and colour family.
struct PieceRow: View {
    let category: Category
    let colorFamily: ColorFamily
    let label: String

    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(label)
                Text(colorFamily == .unknown ? category.label : "\(category.label) · \(colorFamily.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: category.symbol)
        }
    }
}
