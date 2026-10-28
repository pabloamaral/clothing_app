import SwiftUI

/// Where the Pinterest board link and the Anthropic API key are entered.
struct IdeasSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("pinterestBoardLink") private var boardLink = ""
    @State private var apiKey = KeychainStore.apiKey

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("pinterest.com/you/board-name", text: $boardLink)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Pinterest board")
                } footer: {
                    Text("In Pinterest, open a public board, tap Share, then Copy link, and paste it here. The 25 most recent pins are shown.")
                }

                Section {
                    SecureField("sk-ant-…", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Anthropic API key")
                } footer: {
                    Text("Used to compare pins with your closet. Each comparison sends the pin and small copies of your closet photos to Anthropic and is billed to this key. The key is stored in your iPhone's Keychain.")
                }
            }
            .navigationTitle("Ideas Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        KeychainStore.apiKey = apiKey
                        boardLink = boardLink.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                }
            }
        }
    }
}
