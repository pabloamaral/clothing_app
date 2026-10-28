import SwiftUI

/// Hosts both sources of outfit ideas: rules over the closet, and Pinterest looks.
struct IdeasView: View {
    private enum Source: String, CaseIterable, Identifiable {
        case closet = "Closet"
        case pinterest = "Pinterest"
        var id: Self { self }
    }

    @State private var source: Source = .closet
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                switch source {
                case .closet: SuggestionsView()
                case .pinterest: PinterestIdeasView(openSettings: { isShowingSettings = true })
                }
            }
            .navigationTitle("Ideas")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Source", selection: $source) {
                        ForEach(Source.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Settings", systemImage: "gearshape") { isShowingSettings = true }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                IdeasSettingsView()
            }
        }
    }
}
