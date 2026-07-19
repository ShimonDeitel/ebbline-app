import SwiftUI

struct AddIncomeView: View {
    @EnvironmentObject private var store: CashFlowStore
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var source: String = ""
    @State private var amountText: String = ""
    @State private var dateReceived: Date = Date()
    @State private var note: String = ""
    @State private var showPaywallBlock = false

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    private var trimmedSource: String {
        source.trimmingCharacters(in: .whitespaces)
    }

    private var canSave: Bool {
        !trimmedSource.isEmpty && (amount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Income") {
                    TextField("Source (e.g. Acme Co, Uber)", text: $source)
                    HStack {
                        Text("$")
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Date received", selection: $dateReceived, displayedComponents: .date)
                    TextField("Note (optional)", text: $note)
                }

                if !storeManager.isPro && !store.distinctSources.isEmpty {
                    Section {
                        Text("Free tier tracks one income stream: \(store.distinctSources.sorted().joined(separator: ", ")). Upgrade to Pro to add a new source.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle("Log Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { attemptSave() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showPaywallBlock) { PaywallView() }
        }
    }

    private func attemptSave() {
        guard let amount else { return }
        guard CashFlowEngine.canLogIncome(existingSources: store.distinctSources, source: trimmedSource, isPro: storeManager.isPro) else {
            showPaywallBlock = true
            return
        }
        store.addIncome(IncomeEvent(source: trimmedSource, amount: amount, dateReceived: dateReceived, note: note))
        dismiss()
    }
}

#Preview {
    AddIncomeView()
        .environmentObject(CashFlowStore())
        .environmentObject(StoreManager())
}
