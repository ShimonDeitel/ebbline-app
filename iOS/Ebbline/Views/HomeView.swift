import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: CashFlowStore
    @EnvironmentObject private var storeManager: StoreManager

    @State private var showSettings = false
    @State private var showPaywall = false

    private var today: Date { Date() }

    private var safeToSpend: Double {
        CashFlowEngine.safeToSpend(
            events: store.events,
            bills: store.bills,
            nextExpected: store.nextExpected,
            asOf: today,
            billAware: storeManager.isPro
        )
    }

    private var ledgerBalance: Double {
        CashFlowEngine.ledgerBalance(events: store.events, bills: store.bills, asOf: today)
    }

    private var shortfall: CashFlowEngine.ShortfallResult? {
        guard storeManager.isPro, let nextExpected = store.nextExpected else { return nil }
        return CashFlowEngine.shortfall(events: store.events, bills: store.bills, nextExpected: nextExpected, asOf: today)
    }

    private var gaugeMax: Double {
        max(200, ledgerBalance * 1.5, safeToSpend * 1.4)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EbblineTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headline

                        HStack(alignment: .top, spacing: 20) {
                            TideGaugeView(value: safeToSpend, maxValue: gaugeMax, isWarning: shortfall != nil)
                                .frame(width: 96, height: 260)

                            VStack(alignment: .leading, spacing: 14) {
                                statRow(title: "Received to date", value: CashFlowEngine.receivedTotal(events: store.events, through: today))
                                waveDivider
                                statRow(title: "Bills due to date", value: CashFlowEngine.billsTotal(bills: store.bills, through: today))
                                waveDivider
                                statRow(title: "Ledger balance", value: ledgerBalance)

                                if let shortfall {
                                    shortfallBadge(shortfall)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                        .ebblineGlass()

                        FloatLineTimelineView()

                        if !storeManager.isPro {
                            proTeaser
                        }
                    }
                    .padding(20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Ebbline")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(EbblineTheme.foam)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var headline: some View {
        VStack(spacing: 6) {
            Text("Safe to spend today")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(EbblineTheme.foam.opacity(0.85))

            Text(safeToSpend, format: .currency(code: "USD"))
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.8), value: safeToSpend)

            Text(storeManager.isPro ? "Bill-aware — reserves for what's due before your next payment" : "Simple ledger — upgrade for bill-aware recalculation")
                .font(.caption)
                .foregroundStyle(EbblineTheme.foam.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var waveDivider: some View {
        WaveDivider(amplitude: 2.5, wavelength: 30, phase: 0)
            .stroke(EbblineTheme.foam.opacity(0.25), lineWidth: 1.5)
            .frame(height: 8)
    }

    private func statRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .foregroundStyle(EbblineTheme.foam.opacity(0.75))
            Spacer()
            Text(value, format: .currency(code: "USD"))
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
    }

    private func shortfallBadge(_ shortfall: CashFlowEngine.ShortfallResult) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("Shortfall of \(shortfall.amount, format: .currency(code: "USD")) projected by \(shortfall.date.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(10)
        .background(EbblineTheme.shortfallGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var proTeaser: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Unlock bill-aware recalculation, multiple income streams, and the AI shortfall forecaster")
                    .font(.footnote.weight(.medium))
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding(16)
            .ebblineGlass(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environmentObject(CashFlowStore())
        .environmentObject(StoreManager())
}
