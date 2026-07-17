import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, title: String, detail: String)] = [
        ("water.waves", "Multiple income streams", "Track every client and gig, not just one."),
        ("sparkles", "AI shortfall forecaster", "A plain-English warning before you're ever caught short."),
        ("chart.line.uptrend.xyaxis", "Bill-aware recalculation", "Safe-to-spend reserves for what's due before your next payment — live, as you drag the float line.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                EbblineTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Image(systemName: "water.waves")
                                .font(.system(size: 40))
                                .foregroundStyle(EbblineTheme.brightAqua)
                            Text("Ebbline Pro")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Know exactly what's safe to spend — even when your income doesn't arrive on schedule.")
                                .font(.footnote)
                                .foregroundStyle(EbblineTheme.foam.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)

                        VStack(spacing: 14) {
                            ForEach(features, id: \.title) { feature in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: feature.icon)
                                        .font(.title3)
                                        .foregroundStyle(EbblineTheme.aqua)
                                        .frame(width: 30)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(feature.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(feature.detail)
                                            .font(.caption)
                                            .foregroundStyle(EbblineTheme.foam.opacity(0.75))
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(20)
                        .ebblineGlass()

                        VStack(spacing: 10) {
                            Button {
                                Task {
                                    let success = await storeManager.purchase()
                                    if success { dismiss() }
                                }
                            } label: {
                                HStack {
                                    if storeManager.purchaseInFlight {
                                        ProgressView().tint(EbblineTheme.ink)
                                    } else {
                                        Text("Subscribe — \(storeManager.displayPrice)/month")
                                            .font(.headline)
                                    }
                                }
                                .foregroundStyle(EbblineTheme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(EbblineTheme.brightAqua, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(storeManager.purchaseInFlight)

                            Button("Restore Purchases") {
                                Task { await storeManager.restore() }
                            }
                            .font(.footnote)
                            .foregroundStyle(EbblineTheme.foam.opacity(0.8))

                            if let error = storeManager.lastErrorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(EbblineTheme.coral)
                            }

                            Text("Auto-renews monthly. Cancel anytime in Settings.")
                                .font(.caption2)
                                .foregroundStyle(EbblineTheme.foam.opacity(0.5))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: storeManager.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreManager())
}
