import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Closet", systemImage: "square.grid.2x2") {
                ClosetView()
            }
            Tab("Ideas", systemImage: "sparkles") {
                IdeasView()
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
