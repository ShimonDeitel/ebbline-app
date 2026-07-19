import SwiftUI

/// Sheet for setting (or changing) the next expected payment — the thing the
/// float line simulates a delay against.
struct SetExpectedPaymentView: View {
    @EnvironmentObject private var store: CashFlowStore
    @Environment(\.dismiss) private var dismiss

    @State private var source: String
    @State private var amountText: String
    @State private var expectedDate: Date
    @State private var clearRequested = false

    init() {
        _source = State(initialValue: "")
        _amountText = State(initialValue: "")
        _expectedDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date())
    }

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    private var canSave: Bool {
        !source.trimmingCharacters(in: .whitespaces).isEmpty && (amount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expected payment") {
                    TextField("Source (e.g. Acme Invoice #42)", text: $source)
                    HStack {
                        Text("$")
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Expected date", selection: $expectedDate, displayedComponents: .date)
                }

                if store.nextExpected != nil {
                    Section {
                        Button("Clear expected payment", role: .destructive) {
                            store.setNextExpected(nil)
                            dismiss()
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle("Next Expected Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount else { return }
                        store.setNextExpected(
                            ExpectedPayment(source: source.trimmingCharacters(in: .whitespaces), amount: amount, expectedDate: expectedDate)
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let existing = store.nextExpected {
                    source = existing.source
                    amountText = String(format: "%.2f", existing.amount)
                    expectedDate = existing.expectedDate
                }
            }
        }
    }
}

#Preview {
    SetExpectedPaymentView()
        .environmentObject(CashFlowStore())
}
