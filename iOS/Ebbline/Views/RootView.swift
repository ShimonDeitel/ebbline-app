import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Flow", systemImage: "water.waves") }

            LedgerView()
                .tabItem { Label("Ledger", systemImage: "list.bullet.rectangle") }

            ForecastView()
                .tabItem { Label("Forecast", systemImage: "sparkles") }
        }
        .tint(EbblineTheme.aqua)
    }
}

#Preview {
    RootView()
        .environmentObject(CashFlowStore())
        .environmentObject(StoreManager())
}
