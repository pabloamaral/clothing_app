import Foundation

/// A proposed outfit that hasn't been saved yet.
struct OutfitSuggestion: Identifiable {
    let items: [ClothingItem]
    let score: Int
    let reason: String

    var id: [ObjectIdentifier] { items.map(ObjectIdentifier.init) }
}

/// Proposes outfits from the closet using simple colour-harmony rules.
///
/// Every suggestion has a base (a top with a bottom, or a dress), then the
/// best-matching shoes and outerwear are layered on if the closet has any.
enum OutfitRecommender {
    /// Keeps the tops × bottoms search bounded for very large closets.
    private static let maxPerCategory = 40

    static func suggestions(from closet: [ClothingItem], limit: Int = 12) -> [OutfitSuggestion] {
        let byCategory = Dictionary(grouping: closet, by: \.category)
            .mapValues { Array($0.prefix(maxPerCategory)) }

        let tops = byCategory[.top] ?? []
        let bottoms = byCategory[.bottom] ?? []
        let dresses = byCategory[.dress] ?? []
        let shoes = byCategory[.shoes] ?? []
        let outerwear = byCategory[.outerwear] ?? []

        var bases: [[ClothingItem]] = dresses.map { [$0] }
        for top in tops {
            for bottom in bottoms {
                bases.append([top, bottom])
            }
        }

        let suggestions = bases.map { base in
            var outfit = base
            if let pair = bestAddition(from: shoes, for: outfit) { outfit.append(pair) }
            if let layer = bestAddition(from: outerwear, for: outfit) { outfit.append(layer) }
            return OutfitSuggestion(items: outfit, score: score(outfit), reason: reason(for: outfit))
        }

        // A single clashing pair ruins an outfit even if the rest scores well,
        // so clashes are rejected outright rather than averaged away.
        return Array(
            suggestions
                .filter { !hasClash($0.items) }
                .sorted { $0.score > $1.score }
                .prefix(limit)
        )
    }

    /// Picks the candidate that harmonizes best with what's already chosen,
    /// skipping it entirely if every option clashes with something.
    private static func bestAddition(from candidates: [ClothingItem], for outfit: [ClothingItem]) -> ClothingItem? {
        candidates
            .filter { candidate in outfit.allSatisfy { affinity($0, candidate) >= 0 } }
            .max { score(outfit + [$0]) < score(outfit + [$1]) }
    }

    private static func hasClash(_ outfit: [ClothingItem]) -> Bool {
        for i in outfit.indices {
            for j in outfit.indices where j > i && affinity(outfit[i], outfit[j]) < 0 {
                return true
            }
        }
        return false
    }

    /// Total pairwise affinity across every pair of items in the outfit.
    static func score(_ outfit: [ClothingItem]) -> Int {
        var total = 0
        for i in outfit.indices {
            for j in outfit.indices where j > i {
                total += affinity(outfit[i], outfit[j])
            }
        }
        return total
    }

    /// How well two garments go together, from -2 (clash) to 3 (strong match).
    static func affinity(_ a: ClothingItem, _ b: ClothingItem) -> Int {
        let fa = a.colorFamily
        let fb = b.colorFamily

        // Without colour info there's nothing to judge, so stay neutral.
        if fa == .unknown || fb == .unknown { return 0 }
        if fa == .multicolor && fb == .multicolor { return -2 }
        if fa == .multicolor || fb == .multicolor {
            return (fa.isNeutral || fb.isNeutral) ? 2 : -1
        }

        switch (fa.isNeutral, fb.isNeutral) {
        case (true, true): return fa == fb ? 1 : 2
        case (true, false), (false, true): return 3
        case (false, false):
            if fa == fb { return 1 }
            if fa.complements(fb) { return 2 }
            return -2
        }
    }

    private static func reason(for outfit: [ClothingItem]) -> String {
        let families = outfit.map(\.colorFamily).filter { $0 != .unknown }
        guard !families.isEmpty else {
            return "Set colours on these items for better matches"
        }

        let accents = Set(families.filter { !$0.isNeutral && $0 != .multicolor })
        let hasPattern = families.contains(.multicolor)

        if hasPattern {
            return "Pattern balanced by solid pieces"
        }
        switch accents.count {
        case 0:
            return "All neutrals — easy and timeless"
        case 1:
            return "\(accents.first!.label) accent on a neutral base"
        default:
            let names = accents.map(\.label).sorted().joined(separator: " and ")
            return "\(names) complement each other"
        }
    }
}
