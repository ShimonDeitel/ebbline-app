import SwiftUI

struct AddBillView: View {
    @EnvironmentObject private var store: CashFlowStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var dueDate: Date = Date()
    @State private var isPaid: Bool = false

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (amount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bill") {
                    TextField("Name (e.g. Rent, Internet)", text: $name)
                    HStack {
                        Text("$")
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    Toggle("Already paid", isOn: $isPaid)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle("Log Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount else { return }
                        store.addBill(Bill(name: name.trimmingCharacters(in: .whitespaces), amount: amount, dueDate: dueDate, isPaid: isPaid))
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    AddBillView()
        .environmentObject(CashFlowStore())
}
