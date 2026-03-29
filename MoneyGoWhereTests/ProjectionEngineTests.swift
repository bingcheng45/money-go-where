import XCTest
@testable import MoneyGoWhere

final class ProjectionEngineTests: XCTestCase {
    func testMonthlyOccurrencesStayInsideTargetMonth() {
        let engine = ProjectionEngine()
        let item = RecurringItem(
            id: UUID(),
            title: "Netflix",
            merchant: "Netflix",
            category: "Entertainment",
            symbolName: "tv",
            originalAmount: MoneyAmount(amount: 15.49, currencyCode: "USD"),
            homeAmount: MoneyAmount(amount: 15.49, currencyCode: "USD"),
            cadence: .monthly,
            nextDueDate: ISO8601DateFormatter().date(from: "2026-03-15T00:00:00Z") ?? .now,
            itemType: .expense,
            paymentMethodLabel: nil,
            reminder: .disabled,
            source: .manual,
            status: .active,
            createdAt: .now,
            updatedAt: .now
        )

        let monthAnchor = ISO8601DateFormatter().date(from: "2026-04-01T00:00:00Z") ?? .now
        let occurrences = engine.occurrences(for: item, in: monthAnchor)

        XCTAssertEqual(occurrences.count, 1)
        XCTAssertTrue(Calendar.current.isDate(occurrences[0].date, equalTo: monthAnchor, toGranularity: .month))
    }
}

