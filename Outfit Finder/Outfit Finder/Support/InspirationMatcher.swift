import Foundation

/// How closely a closet item fits one piece of an inspiration look.
enum MatchQuality: Int, Comparable {
    /// Same garment type, but the colour is a different neutral or unknown.
    case loose = 1
    /// A neighbouring shade, e.g. navy for black.
    case close
    /// Same colour family.
    case exact

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .exact: "Same colour"
        case .close: "Similar colour"
        case .loose: "Colour differs"
        }
    }
}

/// The closet's best answer for one inspiration piece.
struct PieceMatch {
    let piece: InspirationPiece
    /// Best first; empty when nothing in the closet fits.
    let candidates: [(item: ClothingItem, quality: MatchQuality)]
}

/// Recreates inspiration looks from the closet using the saved piece
/// attributes, so it runs on the device with no network call.
enum InspirationMatcher {
    /// Candidates beyond the best match that are offered as swaps.
    static let maxCandidates = 4

    static func quality(of item: ClothingItem, for piece: InspirationPiece) -> MatchQuality? {
        guard item.category == piece.category else { return nil }

        let want = piece.colorFamily
        let have = item.colorFamily
        if want == .unknown || have == .unknown { return .loose }
        if want == have { return .exact }
        if want.isSimilar(to: have) { return .close }
        // A neutral swapped for another neutral keeps the look's balance;
        // a bright swapped in for a neutral (or vice versa) doesn't.
        if want.isNeutral && have.isNeutral { return .loose }
        return nil
    }

    /// One match per piece. Pieces are filled in order, and an item used for
    /// one piece isn't offered for another (two tops in a layered look).
    static func recreate(_ pieces: [InspirationPiece], from closet: [ClothingItem]) -> [PieceMatch] {
        var used = Set<ObjectIdentifier>()
        return pieces.map { piece in
            let candidates = closet
                .filter { !used.contains(ObjectIdentifier($0)) }
                .compactMap { item in quality(of: item, for: piece).map { (item: item, quality: $0) } }
                .sorted { $0.quality > $1.quality }
                .prefix(maxCandidates)
            if let best = candidates.first {
                used.insert(ObjectIdentifier(best.item))
            }
            return PieceMatch(piece: piece, candidates: Array(candidates))
        }
    }
}
