import Foundation
import SwiftData

/// A single garment the user owns.
@Model
final class ClothingItem {
    var name: String
    var categoryRaw: String
    var colorName: String

    /// Defaulted so existing records migrate without a custom migration plan.
    var colorFamilyRaw: String = ColorFamily.unknown.rawValue
    var notes: String
    var createdAt: Date

    /// Photos can be large, so SwiftData keeps them outside the database file.
    @Attribute(.externalStorage) var imageData: Data?

    /// Outfits this item appears in. The inverse is declared on `Outfit.items`.
    var outfits: [Outfit] = []

    init(
        name: String,
        category: Category,
        colorName: String = "",
        colorFamily: ColorFamily = .unknown,
        notes: String = "",
        imageData: Data? = nil
    ) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.colorName = colorName
        self.colorFamilyRaw = colorFamily.rawValue
        self.notes = notes
        self.imageData = imageData
        self.createdAt = .now
    }

    /// `categoryRaw` is stored as a string so SwiftData can index and sort it;
    /// this is the type-safe way to read and write it.
    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var colorFamily: ColorFamily {
        get { ColorFamily(rawValue: colorFamilyRaw) ?? .unknown }
        set { colorFamilyRaw = newValue.rawValue }
    }
}

enum Category: String, Codable, CaseIterable, Identifiable {
    case top, bottom, dress, outerwear, shoes, accessory, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .top: "Tops"
        case .bottom: "Bottoms"
        case .dress: "Dresses"
        case .outerwear: "Outerwear"
        case .shoes: "Shoes"
        case .accessory: "Accessories"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .top: "tshirt"
        case .bottom: "rectangle.portrait"
        case .dress: "figure.dress.line.vertical.figure"
        case .outerwear: "coat"
        case .shoes: "shoe"
        case .accessory: "eyeglasses"
        case .other: "square.grid.2x2"
        }
    }
}
