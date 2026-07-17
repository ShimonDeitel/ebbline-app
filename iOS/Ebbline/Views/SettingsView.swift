import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CashFlowStore
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var showResetConfirm = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(storeManager.isPro ? "Pro" : "Free")
                            .foregroundStyle(storeManager.isPro ? EbblineTheme.aqua : .secondary)
                            .fontWeight(.semibold)
                    }
                    if !storeManager.isPro {
                        Button("Upgrade to Pro") { showPaywall = true }
                    }
                    Button("Restore Purchases") {
                        Task { await storeManager.restore() }
                    }
                }

                Section("Your Data") {
                    Text("Ebbline has no bank connection and no account. Everything you've logged lives only on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                }

                Section("Legal") {
                    Link("Privacy Policy", destination: URL(string: "https://s0533495227.github.io/ebbline/privacy.html")!)
                    Link("Terms of Use", destination: URL(string: "https://s0533495227.github.io/ebbline/terms.html")!)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete every income entry, bill, and expected payment? This can't be undone.",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset All Data", role: .destructive) {
                    store.resetAll()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CashFlowStore())
        .environmentObject(StoreManager())
}
