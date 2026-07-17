import SwiftUI

@main
struct EbblineApp: App {
    @StateObject private var store = CashFlowStore()
    @StateObject private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(storeManager)
                .preferredColorScheme(.dark)
        }
    }
}
