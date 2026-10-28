import SwiftUI
import SwiftData

/// The coming week, with an outfit assignable to each day.
struct PlannerView: View {
    @Environment(\.modelContext) private var context
    @Query private var plans: [PlannedDay]
    @Query(sort: \Outfit.name) private var outfits: [Outfit]

    private let daysAhead = 7

    /// The upcoming dates, normalized to midnight.
    private var upcomingDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<daysAhead).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if outfits.isEmpty {
                    ContentUnavailableView(
                        "Nothing to plan yet",
                        systemImage: "calendar",
                        description: Text("Create an outfit before planning your week.")
                    )
                } else {
                    List(upcomingDays, id: \.self) { day in
                        DayRow(
                            day: day,
                            outfits: outfits,
                            selection: plan(for: day)?.outfit
                        ) { chosen in
                            assign(chosen, to: day)
                        }
                    }
                }
            }
            .navigationTitle("Planner")
        }
    }

    private func plan(for day: Date) -> PlannedDay? {
        plans.first { $0.day == day }
    }

    private func assign(_ outfit: Outfit?, to day: Date) {
        if let existing = plan(for: day) {
            if let outfit {
                existing.outfit = outfit
            } else {
                // Clearing a day removes its entry rather than leaving an empty one.
                context.delete(existing)
            }
        } else if let outfit {
            context.insert(PlannedDay(day: day, outfit: outfit))
        }
    }
}

private struct DayRow: View {
    let day: Date
    let outfits: [Outfit]
    let selection: Outfit?
    let onSelect: (Outfit?) -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                if isToday {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }

            Spacer()

            Menu {
                Button("None") { onSelect(nil) }
                Divider()
                ForEach(outfits) { outfit in
                    Button(outfit.name) { onSelect(outfit) }
                }
            } label: {
                Text(selection?.name ?? "Choose…")
                    .font(.subheadline)
                    .foregroundStyle(selection == nil ? .secondary : .primary)
            }
        }
        .padding(.vertical, 2)
    }
}
