import XCTest
@testable import Ebbline

/// Hand-verified tests for `CashFlowEngine`, the pure cash-flow math that
/// powers the safe-to-spend figure, the float-line simulation, and the
/// free/Pro income-stream gate.
///
/// Fixture, used throughout (dates in UTC to avoid timezone flakiness):
///   Income:
///     E1  "Design Client"  $1200  received Jan 1, 2026
///     E2  "Design Client"  $800   received Jan 10, 2026
///     E3  "Consulting"     $500   received Jan 15, 2026
///   Bills:
///     B1  "Rent"           $1000  due Jan 5, 2026
///     B2  "Internet"       $60    due Jan 20, 2026
///     B3  "Insurance"      $300   due Jan 25, 2026
///     B4  "Tax Payment"    $900   due Jan 28, 2026
///   asOf = Jan 12, 2026
final class EbblineLogicTests: XCTestCase {

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }

    private var events: [IncomeEvent] {
        [
            IncomeEvent(source: "Design Client", amount: 1200, dateReceived: date(2026, 1, 1)),
            IncomeEvent(source: "Design Client", amount: 800, dateReceived: date(2026, 1, 10)),
            IncomeEvent(source: "Consulting", amount: 500, dateReceived: date(2026, 1, 15))
        ]
    }

    private var bills: [Bill] {
        [
            Bill(name: "Rent", amount: 1000, dueDate: date(2026, 1, 5)),
            Bill(name: "Internet", amount: 60, dueDate: date(2026, 1, 20)),
            Bill(name: "Insurance", amount: 300, dueDate: date(2026, 1, 25)),
            Bill(name: "Tax Payment", amount: 900, dueDate: date(2026, 1, 28))
        ]
    }

    private var asOf: Date { date(2026, 1, 12) }

    // MARK: - Received / billed totals

    func testReceivedTotal_sumsOnlyEventsOnOrBeforeDate() {
        // E1 (Jan 1) + E2 (Jan 10) = 2000; E3 (Jan 15) is after asOf and excluded.
        let total = CashFlowEngine.receivedTotal(events: events, through: asOf)
        XCTAssertEqual(total, 2000, accuracy: 0.001)
    }

    func testBillsTotal_sumsOnlyBillsDueOnOrBeforeDate() {
        // Only B1 (Jan 5) is due on or before Jan 12.
        let total = CashFlowEngine.billsTotal(bills: bills, through: asOf)
        XCTAssertEqual(total, 1000, accuracy: 0.001)
    }

    func testLedgerBalance_isReceivedMinusBillsDue() {
        // 2000 received - 1000 due = 1000.
        let balance = CashFlowEngine.ledgerBalance(events: events, bills: bills, asOf: asOf)
        XCTAssertEqual(balance, 1000, accuracy: 0.001)
    }

    // MARK: - Reserve window

    func testReservedForUpcomingBills_onlyCountsBillsInOpenClosedWindow() {
        // Window (Jan 12, Jan 22]: only Internet (Jan 20) qualifies; Insurance
        // (Jan 25) and Tax Payment (Jan 28) fall outside the window.
        let reserved = CashFlowEngine.reservedForUpcomingBills(bills: bills, from: asOf, until: date(2026, 1, 22))
        XCTAssertEqual(reserved, 60, accuracy: 0.001)
    }

    // MARK: - safe-to-spend

    func testSafeToSpend_billAwareReservesForUpcomingBills() {
        let nextExpected = ExpectedPayment(source: "Client X", amount: 1500, expectedDate: date(2026, 1, 22))
        // ledger 1000 - reserved 60 (Internet only) = 940.
        let safe = CashFlowEngine.safeToSpend(events: events, bills: bills, nextExpected: nextExpected, asOf: asOf, billAware: true)
        XCTAssertEqual(safe, 940, accuracy: 0.001)
    }

    func testSafeToSpend_freeTierIgnoresFutureBillsEntirely() {
        let nextExpected = ExpectedPayment(source: "Client X", amount: 1500, expectedDate: date(2026, 1, 22))
        // Free tier (billAware == false) never reserves, regardless of nextExpected.
        let safe = CashFlowEngine.safeToSpend(events: events, bills: bills, nextExpected: nextExpected, asOf: asOf, billAware: false)
        XCTAssertEqual(safe, 1000, accuracy: 0.001)
    }

    func testSafeToSpend_clampsAtZeroWhenReserveExceedsLedger() {
        let nextExpected = ExpectedPayment(source: "Client X", amount: 1500, expectedDate: date(2026, 1, 30))
        // Reserved = Internet(60) + Insurance(300) + Tax(900) = 1260 > ledger 1000, so raw is -260.
        let safe = CashFlowEngine.safeToSpend(events: events, bills: bills, nextExpected: nextExpected, asOf: asOf, billAware: true)
        XCTAssertEqual(safe, 0, accuracy: 0.001)

        let raw = CashFlowEngine.rawProjectedBalance(events: events, bills: bills, until: date(2026, 1, 30), asOf: asOf)
        XCTAssertEqual(raw, -260, accuracy: 0.001)
    }

    // MARK: - minimum balance projection

    func testMinimumBalance_findsDipAndNoDipCases() {
        // Dip case: window (Jan 12, Jan 30] walks Internet -> Insurance -> Tax
        // Payment: 1000 -> 940 -> 640 -> -260. Lowest point is -260 on Jan 28.
        let dip = CashFlowEngine.minimumBalance(ledgerStart: 1000, bills: bills, asOf: asOf, until: date(2026, 1, 30))
        XCTAssertEqual(dip.minBalance, -260, accuracy: 0.001)
        XCTAssertEqual(dip.minDate, date(2026, 1, 28))

        // No-dip case: window (Jan 12, Jan 15] contains no bills at all, so
        // the balance never drops below the starting point and minDate is nil.
        let noDip = CashFlowEngine.minimumBalance(ledgerStart: 1000, bills: bills, asOf: asOf, until: date(2026, 1, 15))
        XCTAssertEqual(noDip.minBalance, 1000, accuracy: 0.001)
        XCTAssertNil(noDip.minDate)
    }

    // MARK: - shortfall detection

    func testShortfall_detectsShortfallAndReturnsNilWhenCovered() {
        let latePayment = ExpectedPayment(source: "Client X", amount: 1500, expectedDate: date(2026, 1, 30))
        let result = CashFlowEngine.shortfall(events: events, bills: bills, nextExpected: latePayment, asOf: asOf)
        XCTAssertEqual(result, CashFlowEngine.ShortfallResult(date: date(2026, 1, 28), amount: 260))

        // If the next expected payment lands before any bill comes due, there's no shortfall.
        let earlyPayment = ExpectedPayment(source: "Client X", amount: 1500, expectedDate: date(2026, 1, 15))
        let noShortfall = CashFlowEngine.shortfall(events: events, bills: bills, nextExpected: earlyPayment, asOf: asOf)
        XCTAssertNil(noShortfall)
    }

    // MARK: - free/Pro income-stream gate

    func testCanLogIncome_freeTierGatesSecondDistinctStreamButProAllows() {
        let existing: Set<String> = ["Design Client"]

        // Free tier: logging another event against the SAME stream is fine.
        XCTAssertTrue(CashFlowEngine.canLogIncome(existingSources: existing, source: "Design Client", isPro: false))

        // Free tier: introducing a brand-new distinct stream is blocked.
        XCTAssertFalse(CashFlowEngine.canLogIncome(existingSources: existing, source: "Consulting", isPro: false))

        // Pro: any new stream is allowed.
        XCTAssertTrue(CashFlowEngine.canLogIncome(existingSources: existing, source: "Consulting", isPro: true))

        // Free tier: the very first stream ever logged is always allowed.
        XCTAssertTrue(CashFlowEngine.canLogIncome(existingSources: [], source: "Anything", isPro: false))
    }
}
