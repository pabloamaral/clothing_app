import Foundation
import SwiftData

/// A photo of a complete outfit the user wants to recreate.
@Model
final class InspirationLook {
    var title: String
    var createdAt: Date
    @Attribute(.externalStorage) var imageData: Data?

    @Relationship(deleteRule: .cascade, inverse: \InspirationPiece.look)
    var pieces: [InspirationPiece] = []

    /// nil means unfiled. The inverse is declared on `InspirationFolder.looks`.
    var folder: InspirationFolder?

    init(title: String, imageData: Data?, folder: InspirationFolder? = nil) {
        self.title = title
        self.imageData = imageData
        self.folder = folder
        self.createdAt = .now
    }

    /// SwiftData doesn't preserve the order of to-many relationships, so
    /// pieces carry an explicit position.
    var orderedPieces: [InspirationPiece] {
        pieces.sorted { $0.position < $1.position }
    }
}

/// One garment seen in an inspiration photo, such as "olive wide-leg chinos".
@Model
final class InspirationPiece {
    var categoryRaw: String
    var colorFamilyRaw: String
    var colorName: String
    var details: String
    var position: Int
    var look: InspirationLook?

    init(category: Category, colorFamily: ColorFamily, colorName: String, details: String, position: Int) {
        self.categoryRaw = category.rawValue
        self.colorFamilyRaw = colorFamily.rawValue
        self.colorName = colorName
        self.details = details
        self.position = position
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var colorFamily: ColorFamily {
        get { ColorFamily(rawValue: colorFamilyRaw) ?? .unknown }
        set { colorFamilyRaw = newValue.rawValue }
    }

    var label: String {
        Self.label(category: category, colorName: colorName, details: details)
    }

    /// e.g. "Olive wide-leg chinos", falling back to the category name.
    /// Static so unsaved drafts can share it.
    static func label(category: Category, colorName: String, details: String) -> String {
        let parts = [colorName, details].filter { !$0.isEmpty }
        guard !parts.isEmpty else { return category.label }
        let text = parts.joined(separator: " ")
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
