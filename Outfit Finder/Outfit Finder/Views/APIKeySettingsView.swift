import SwiftUI

/// Where the Anthropic API key used for photo analysis is entered.
struct APIKeySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = KeychainStore.apiKey

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-…", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Anthropic API key")
                } footer: {
                    Text("Used to detect the pieces in inspiration photos you add. Only those photos are sent to Anthropic, once each, billed to this key. Your closet photos never leave the phone. The key is stored in your iPhone's Keychain.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        KeychainStore.apiKey = apiKey
                        dismiss()
                    }
                }
            }
        }
    }
}
