import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Closet", systemImage: "square.grid.2x2") {
                ClosetView()
            }
            Tab("Inspiration", systemImage: "photo.stack") {
                InspirationView()
            }
            Tab("Ideas", systemImage: "sparkles") {
                SuggestionsView()
            }
            Tab("Outfits", systemImage: "hanger") {
                OutfitsView()
            }
            Tab("Planner", systemImage: "calendar") {
                PlannerView()
            }
        }
    }
}
