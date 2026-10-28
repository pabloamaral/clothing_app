import Foundation
import SwiftData

/// An outfit assigned to one calendar day.
@Model
final class PlannedDay {
    /// Always normalized to midnight so one day has at most one entry.
    @Attribute(.unique) var day: Date

    @Relationship(inverse: \Outfit.plannedDays)
    var outfit: Outfit?

    init(day: Date, outfit: Outfit? = nil) {
        self.day = Calendar.current.startOfDay(for: day)
        self.outfit = outfit
    }
}
