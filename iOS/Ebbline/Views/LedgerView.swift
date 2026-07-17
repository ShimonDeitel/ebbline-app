import SwiftUI

struct LedgerView: View {
    @EnvironmentObject private var store: CashFlowStore

    @State private var showAddIncome = false
    @State private var showAddBill = false

    var body: some View {
        NavigationStack {
            ZStack {
                EbblineTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        section(
                            title: "Income received",
                            actionTitle: "Add income",
                            action: { showAddIncome = true }
                        ) {
                            if store.events.isEmpty {
                                emptyRow("No income logged yet. Add the first payment you've actually received.")
                            } else {
                                ForEach(store.events.sorted(by: { $0.dateReceived > $1.dateReceived })) { event in
                                    incomeRow(event)
                                    waveDivider
                                }
                            }
                        }

                        section(
                            title: "Bills",
                            actionTitle: "Add bill",
                            action: { showAddBill = true }
                        ) {
                            if store.bills.isEmpty {
                                emptyRow("No bills logged yet. Add what you know is coming due.")
                            } else {
                                ForEach(store.bills.sorted(by: { $0.dueDate < $1.dueDate })) { bill in
                                    billRow(bill)
                                    waveDivider
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Ledger")
        }
        .sheet(isPresented: $showAddIncome) { AddIncomeView() }
        .sheet(isPresented: $showAddBill) { AddBillView() }
    }

    private func section<Content: View>(
        title: String,
        actionTitle: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button(actionTitle, action: action)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(EbblineTheme.aqua)
            }
            VStack(spacing: 0) { content() }
        }
        .padding(20)
        .ebblineGlass()
    }

    private var waveDivider: some View {
        WaveDivider(amplitude: 2, wavelength: 26, phase: 0)
            .stroke(EbblineTheme.foam.opacity(0.18), lineWidth: 1)
            .frame(height: 6)
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(EbblineTheme.foam.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    private func incomeRow(_ event: IncomeEvent) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.source)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(event.dateReceived.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(EbblineTheme.foam.opacity(0.6))
            }
            Spacer()
            Text(event.amount, format: .currency(code: "USD"))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(EbblineTheme.brightAqua)
        }
        .padding(.vertical, 8)
        .swipeActions {
            Button(role: .destructive) {
                store.removeIncome(event)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func billRow(_ bill: Bill) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text("Due \(bill.dueDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(EbblineTheme.foam.opacity(0.6))
            }
            Spacer()
            Text(bill.amount, format: .currency(code: "USD"))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(bill.isPaid ? EbblineTheme.foam.opacity(0.5) : EbblineTheme.coral)
            Button {
                store.togglePaid(bill)
            } label: {
                Image(systemName: bill.isPaid ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(bill.isPaid ? EbblineTheme.brightAqua : EbblineTheme.foam.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .swipeActions {
            Button(role: .destructive) {
                store.removeBill(bill)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    LedgerView()
        .environmentObject(CashFlowStore())
        .environmentObject(StoreManager())
}
