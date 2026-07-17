import Foundation

/// Pure, deterministic cash-flow math. No I/O, no singletons, no dates read
/// from `Date()` internally — every function takes `asOf`/`through` explicitly
/// so it is fully unit-testable and safe to call live from a drag gesture.
enum CashFlowEngine {

    /// Sum of income actually logged as received on or before `date`.
    static func receivedTotal(events: [IncomeEvent], through date: Date) -> Double {
        events.filter { $0.dateReceived <= date }.reduce(0) { $0 + $1.amount }
    }

    /// Sum of bills due on or before `date` — obligations already incurred,
    /// regardless of whether the user has marked them paid.
    static func billsTotal(bills: [Bill], through date: Date) -> Double {
        bills.filter { $0.dueDate <= date }.reduce(0) { $0 + $1.amount }
    }

    /// Cash actually on hand as of `date`: everything received minus
    /// everything already due.
    static func ledgerBalance(events: [IncomeEvent], bills: [Bill], asOf date: Date) -> Double {
        receivedTotal(events: events, through: date) - billsTotal(bills: bills, through: date)
    }

    /// Sum of bills strictly after `from` and on/before `until` — the
    /// reserve a bill-aware forecast sets aside for known obligations that
    /// land before the next expected payment.
    static func reservedForUpcomingBills(bills: [Bill], from: Date, until: Date) -> Double {
        guard until > from else { return 0 }
        return bills
            .filter { $0.dueDate > from && $0.dueDate <= until }
            .reduce(0) { $0 + $1.amount }
    }

    /// The headline "safe-to-spend-today" figure.
    ///
    /// - `billAware == false` (free tier): the raw ledger balance, clamped at
    ///   zero. Simple, honest, but doesn't look ahead.
    /// - `billAware == true` (Pro): the ledger balance minus whatever is
    ///   reserved for bills due before `nextExpected`, clamped at zero. This
    ///   is the number the float-line drag recalculates live.
    static func safeToSpend(
        events: [IncomeEvent],
        bills: [Bill],
        nextExpected: ExpectedPayment?,
        asOf date: Date,
        billAware: Bool
    ) -> Double {
        let ledger = ledgerBalance(events: events, bills: bills, asOf: date)
        guard billAware, let nextExpected else { return max(0, ledger) }
        let reserved = reservedForUpcomingBills(bills: bills, from: date, until: nextExpected.expectedDate)
        return max(0, ledger - reserved)
    }

    /// The *unclamped* projection used to detect a genuine shortfall — i.e.
    /// how negative the balance would actually go, not the floor-at-zero
    /// display figure.
    static func rawProjectedBalance(
        events: [IncomeEvent],
        bills: [Bill],
        until date: Date,
        asOf: Date
    ) -> Double {
        let ledger = ledgerBalance(events: events, bills: bills, asOf: asOf)
        let reserved = reservedForUpcomingBills(bills: bills, from: asOf, until: date)
        return ledger - reserved
    }

    /// Walks every bill due in `(asOf, endDate]` in date order and returns the
    /// lowest running balance reached and the date it was reached. If the
    /// balance never dips below `ledgerStart`, `minDate` is `nil`.
    static func minimumBalance(
        ledgerStart: Double,
        bills: [Bill],
        asOf: Date,
        until endDate: Date
    ) -> (minBalance: Double, minDate: Date?) {
        let upcoming = bills
            .filter { $0.dueDate > asOf && $0.dueDate <= endDate }
            .sorted { $0.dueDate < $1.dueDate }

        var running = ledgerStart
        var minBalance = ledgerStart
        var minDate: Date?

        for bill in upcoming {
            running -= bill.amount
            if running < minBalance {
                minBalance = running
                minDate = bill.dueDate
            }
        }
        return (minBalance, minDate)
    }

    /// Result of checking whether the *real* trajectory (using the actually
    /// expected payment date, not a hypothetical drag) goes negative before
    /// that payment lands.
    struct ShortfallResult: Equatable {
        let date: Date
        let amount: Double
    }

    static func shortfall(
        events: [IncomeEvent],
        bills: [Bill],
        nextExpected: ExpectedPayment,
        asOf date: Date
    ) -> ShortfallResult? {
        let ledger = ledgerBalance(events: events, bills: bills, asOf: date)
        let (minBalance, minDate) = minimumBalance(
            ledgerStart: ledger,
            bills: bills,
            asOf: date,
            until: nextExpected.expectedDate
        )
        guard minBalance < 0, let minDate else { return nil }
        return ShortfallResult(date: minDate, amount: -minBalance)
    }

    /// The set of distinct income source names logged so far.
    static func distinctSources(events: [IncomeEvent]) -> Set<String> {
        Set(events.map { $0.source })
    }

    /// Free tier is limited to a single distinct income stream name; logging
    /// another event against an *existing* source is always fine, only
    /// introducing a brand-new distinct source is gated behind Pro.
    static func canLogIncome(existingSources: Set<String>, source: String, isPro: Bool) -> Bool {
        if isPro { return true }
        if existingSources.isEmpty || existingSources.contains(source) { return true }
        return false
    }
}
