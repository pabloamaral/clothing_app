import SwiftUI
import SwiftData

@main
struct OutfitPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            ClothingItem.self, Outfit.self, PlannedDay.self,
            InspirationFolder.self, InspirationLook.self, InspirationPiece.self,
        ])
    }
}
