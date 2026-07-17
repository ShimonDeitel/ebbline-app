import Foundation

/// Client for the shared, keyless AI proxy. Builds a plain-English shortfall
/// forecast from income already logged as received and known upcoming bills.
/// Every failure path returns a plain, user-facing message — this feature
/// must never crash the app or leave the caller hanging.
final class AIProxyClient {
    static let shared = AIProxyClient()

    private let endpoint = URL(string: "https://apps-ai-proxy.s0533495227.workers.dev/text")!

    enum ProxyError: Error, LocalizedError {
        case network
        case badResponse
        case empty

        var errorDescription: String? {
            switch self {
            case .network:
                return "Couldn't reach the forecast service. Check your connection and try again."
            case .badResponse:
                return "The forecast service returned something unexpected. Try again in a moment."
            case .empty:
                return "The forecast came back empty. Try again in a moment."
            }
        }
    }

    private struct ChatMessage: Codable {
        let role: String
        let content: String
    }

    private struct ChatRequestBody: Codable {
        let messages: [ChatMessage]
    }

    private struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    private static let systemPrompt = """
    You are Ebbline's cash-flow forecaster for a freelancer with irregular income. \
    You will be given the current cash balance, recent income already received, and \
    known upcoming bills, plus the next expected payment. If the balance would go \
    negative before that next payment arrives, reply with exactly one short, specific, \
    plain-English sentence naming the exact date and the exact shortfall dollar amount. \
    If there is no shortfall, reply with exactly one short, reassuring plain-English \
    sentence confirming they are covered through the next expected payment. Never use \
    jargon, never add a preamble, never use markdown, never use more than one sentence.
    """

    func forecastShortfall(
        events: [IncomeEvent],
        bills: [Bill],
        nextExpected: ExpectedPayment?,
        asOf date: Date
    ) async -> Result<String, ProxyError> {
        let userPrompt = buildUserPrompt(events: events, bills: bills, nextExpected: nextExpected, asOf: date)

        let body = ChatRequestBody(messages: [
            ChatMessage(role: "system", content: Self.systemPrompt),
            ChatMessage(role: "user", content: userPrompt)
        ])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return .failure(.badResponse)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return .failure(.badResponse)
            }
            let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
            guard let content = decoded.choices.first?.message.content
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !content.isEmpty
            else {
                return .failure(.empty)
            }
            return .success(content)
        } catch is DecodingError {
            return .failure(.badResponse)
        } catch {
            return .failure(.network)
        }
    }

    private func buildUserPrompt(
        events: [IncomeEvent],
        bills: [Bill],
        nextExpected: ExpectedPayment?,
        asOf date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        var lines: [String] = []
        lines.append("Today: \(formatter.string(from: date))")

        let ledger = CashFlowEngine.ledgerBalance(events: events, bills: bills, asOf: date)
        lines.append("Current cash balance (income received minus bills already due): $\(formattedAmount(ledger))")

        lines.append("Recent income received:")
        if events.isEmpty {
            lines.append("- none logged yet")
        } else {
            for event in events.sorted(by: { $0.dateReceived > $1.dateReceived }).prefix(10) {
                lines.append("- $\(formattedAmount(event.amount)) from \(event.source) on \(formatter.string(from: event.dateReceived))")
            }
        }

        lines.append("Known upcoming bills:")
        let upcoming = bills.filter { $0.dueDate > date }.sorted { $0.dueDate < $1.dueDate }
        if upcoming.isEmpty {
            lines.append("- none logged")
        } else {
            for bill in upcoming.prefix(10) {
                lines.append("- $\(formattedAmount(bill.amount)) (\(bill.name)) due \(formatter.string(from: bill.dueDate))")
            }
        }

        if let nextExpected {
            lines.append("Next expected payment: $\(formattedAmount(nextExpected.amount)) from \(nextExpected.source), expected \(formatter.string(from: nextExpected.expectedDate))")
        } else {
            lines.append("No next expected payment has been set — treat there as being no future income to reserve against.")
        }

        return lines.joined(separator: "\n")
    }

    private func formattedAmount(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
