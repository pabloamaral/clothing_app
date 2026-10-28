import Foundation
import SwiftData

/// A named combination of garments.
@Model
final class Outfit {
    var name: String
    var notes: String
    var createdAt: Date

    @Relationship(inverse: \ClothingItem.outfits)
    var items: [ClothingItem] = []

    /// Days this outfit is planned for.
    var plannedDays: [PlannedDay] = []

    init(name: String, notes: String = "", items: [ClothingItem] = []) {
        self.name = name
        self.notes = notes
        self.items = items
        self.createdAt = .now
    }

    /// Items grouped by category, in the order `Category` declares them.
    var itemsByCategory: [(Category, [ClothingItem])] {
        Category.allCases.compactMap { category in
            let matches = items.filter { $0.category == category }
            return matches.isEmpty ? nil : (category, matches)
        }
    }
}
