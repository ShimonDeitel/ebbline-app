import Foundation

/// UserDefaults-backed persistence for everything the user has logged.
/// Ebbline has no bank link and no server-side account — this is the entire
/// data layer, on-device only.
@MainActor
final class CashFlowStore: ObservableObject {
    @Published private(set) var events: [IncomeEvent] = []
    @Published private(set) var bills: [Bill] = []
    @Published private(set) var nextExpected: ExpectedPayment?

    private let defaults: UserDefaults
    private let eventsKey = "ebbline.events.v1"
    private let billsKey = "ebbline.bills.v1"
    private let nextExpectedKey = "ebbline.nextExpected.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: - Mutation

    func addIncome(_ event: IncomeEvent) {
        events.append(event)
        persistEvents()
    }

    func removeIncome(_ event: IncomeEvent) {
        events.removeAll { $0.id == event.id }
        persistEvents()
    }

    func addBill(_ bill: Bill) {
        bills.append(bill)
        persistBills()
    }

    func removeBill(_ bill: Bill) {
        bills.removeAll { $0.id == bill.id }
        persistBills()
    }

    func togglePaid(_ bill: Bill) {
        guard let index = bills.firstIndex(where: { $0.id == bill.id }) else { return }
        bills[index].isPaid.toggle()
        persistBills()
    }

    func setNextExpected(_ payment: ExpectedPayment?) {
        nextExpected = payment
        persistNextExpected()
    }

    func resetAll() {
        events = []
        bills = []
        nextExpected = nil
        persistEvents()
        persistBills()
        persistNextExpected()
    }

    // MARK: - Derived

    var distinctSources: Set<String> {
        CashFlowEngine.distinctSources(events: events)
    }

    // MARK: - Persistence

    private func load() {
        if let data = defaults.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([IncomeEvent].self, from: data) {
            events = decoded
        }
        if let data = defaults.data(forKey: billsKey),
           let decoded = try? JSONDecoder().decode([Bill].self, from: data) {
            bills = decoded
        }
        if let data = defaults.data(forKey: nextExpectedKey),
           let decoded = try? JSONDecoder().decode(ExpectedPayment.self, from: data) {
            nextExpected = decoded
        }
    }

    private func persistEvents() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        defaults.set(data, forKey: eventsKey)
    }

    private func persistBills() {
        guard let data = try? JSONEncoder().encode(bills) else { return }
        defaults.set(data, forKey: billsKey)
    }

    private func persistNextExpected() {
        if let nextExpected, let data = try? JSONEncoder().encode(nextExpected) {
            defaults.set(data, forKey: nextExpectedKey)
        } else {
            defaults.removeObject(forKey: nextExpectedKey)
        }
    }
}
