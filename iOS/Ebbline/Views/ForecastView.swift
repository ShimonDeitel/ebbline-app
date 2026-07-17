import SwiftUI

struct ForecastView: View {
    @EnvironmentObject private var store: CashFlowStore
    @EnvironmentObject private var storeManager: StoreManager

    @State private var isLoading = false
    @State private var forecastText: String?
    @State private var errorText: String?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                EbblineTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 34))
                                .foregroundStyle(EbblineTheme.brightAqua)
                            Text("AI Shortfall Forecaster")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Ebbline reads your logged income and upcoming bills and tells you, in plain English, whether you're covered until your next expected payment.")
                                .font(.footnote)
                                .foregroundStyle(EbblineTheme.foam.opacity(0.75))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)

                        if storeManager.isPro {
                            proContent
                        } else {
                            lockedContent
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Forecast")
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var proContent: some View {
        VStack(spacing: 16) {
            Button {
                Task { await runForecast() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView().tint(EbblineTheme.ink)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isLoading ? "Reading your ledger…" : "Get my forecast")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(EbblineTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(EbblineTheme.brightAqua, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            if let forecastText {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Forecast", systemImage: "text.bubble.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EbblineTheme.aqua)
                    Text(forecastText)
                        .font(.body)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .ebblineGlass()
            }

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(EbblineTheme.coral)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var lockedContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundStyle(EbblineTheme.foam.opacity(0.6))
            Text("The AI shortfall forecaster is a Pro feature.")
                .font(.footnote)
                .foregroundStyle(EbblineTheme.foam.opacity(0.8))
            Button("Unlock Pro") { showPaywall = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(EbblineTheme.ink)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(EbblineTheme.aqua, in: Capsule())
        }
        .padding(24)
        .ebblineGlass()
    }

    private func runForecast() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        let result = await AIProxyClient.shared.forecastShortfall(
            events: store.events,
            bills: store.bills,
            nextExpected: store.nextExpected,
            asOf: Date()
        )

        switch result {
        case .success(let text):
            forecastText = text
        case .failure(let error):
            errorText = error.errorDescription
        }
    }
}

#Preview {
    ForecastView()
        .environmentObject(CashFlowStore())
        .environmentObject(StoreManager())
}
