import Foundation
import SwiftData

/// A named group of inspiration photos, such as "Work" or "Date night".
@Model
final class InspirationFolder {
    var name: String
    var createdAt: Date

    /// Deleting a folder leaves its looks unfiled; callers that want them
    /// gone delete them explicitly.
    @Relationship(deleteRule: .nullify, inverse: \InspirationLook.folder)
    var looks: [InspirationLook] = []

    init(name: String) {
        self.name = name
        self.createdAt = .now
    }

    /// Newest first, matching the unfiled list.
    var sortedLooks: [InspirationLook] {
        looks.sorted { $0.createdAt > $1.createdAt }
    }
}
