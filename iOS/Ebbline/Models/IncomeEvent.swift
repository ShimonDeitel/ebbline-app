import Foundation

/// A single logged receipt of income — money the user has confirmed actually
/// arrived. Ebbline never counts a payment until it is logged here; there is
/// no bank link and no projection of income that "should" arrive.
struct IncomeEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var source: String
    var amount: Double
    var dateReceived: Date
    var note: String

    init(id: UUID = UUID(), source: String, amount: Double, dateReceived: Date, note: String = "") {
        self.id = id
        self.source = source
        self.amount = amount
        self.dateReceived = dateReceived
        self.note = note
    }
}
