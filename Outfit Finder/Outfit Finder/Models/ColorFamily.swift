import Foundation

/// A coarse colour bucket. Free-text colour names are too varied to match on,
/// so the recommender reasons about these instead.
enum ColorFamily: String, Codable, CaseIterable, Identifiable {
    case unknown
    case black, white, gray, beige, brown, navy
    case blue, green, red, pink, yellow, orange, purple
    case multicolor

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unknown: "Not set"
        case .multicolor: "Multicolour / pattern"
        default: rawValue.capitalized
        }
    }

    /// Neutrals go with almost anything, which is the backbone of the pairing rules.
    var isNeutral: Bool {
        switch self {
        case .black, .white, .gray, .beige, .brown, .navy: true
        default: false
        }
    }

    /// Opposite-ish hues that look deliberate together rather than accidental.
    private static let complements: [Set<ColorFamily>] = [
        [.blue, .orange],
        [.red, .green],
        [.yellow, .purple],
        [.pink, .green],
        [.blue, .yellow],
    ]

    func complements(_ other: ColorFamily) -> Bool {
        Self.complements.contains([self, other])
    }

    /// Neighbouring shades that read as "the same colour" from a distance,
    /// so navy chinos can stand in for black ones.
    private static let similar: [Set<ColorFamily>] = [
        [.black, .gray, .navy],
        [.white, .beige],
        [.beige, .brown],
        [.blue, .navy],
        [.red, .pink],
        [.red, .orange],
        [.orange, .yellow],
        [.pink, .purple],
        [.blue, .purple],
    ]

    func isSimilar(to other: ColorFamily) -> Bool {
        Self.similar.contains { $0.contains(self) && $0.contains(other) }
    }
}
