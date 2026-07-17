import Foundation

/// A payment the user believes is coming but which has NOT been logged as
/// received yet. This is what the float-line timeline drags: the user is
/// simulating "what if this arrives later than expected" by moving
/// `expectedDate` forward and watching the safe-to-spend number react.
struct ExpectedPayment: Identifiable, Codable, Equatable {
    let id: UUID
    var source: String
    var amount: Double
    var expectedDate: Date

    init(id: UUID = UUID(), source: String, amount: Double, expectedDate: Date) {
        self.id = id
        self.source = source
        self.amount = amount
        self.expectedDate = expectedDate
    }
}
