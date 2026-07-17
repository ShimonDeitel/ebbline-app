import Foundation

/// A known obligation — recurring or one-off — with a due date and amount.
/// Bills due on or before "today" are treated as money that has already left
/// (or must leave) the account, whether or not the user has flagged them
/// paid; bills due in the future are what the bill-aware recalculation
/// reserves against.
struct Bill: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var amount: Double
    var dueDate: Date
    var isPaid: Bool

    init(id: UUID = UUID(), name: String, amount: Double, dueDate: Date, isPaid: Bool = false) {
        self.id = id
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
    }
}
