import XCTest
@testable import MoneyGoWhere

final class InsightsEngineTests: XCTestCase {
    func testDuplicateInsightAppears() {
        let engine = InsightsEngine()
        let catalog = CatalogService()
        let now = ISO8601DateFormatter().date(from: "2026-03-01T00:00:00Z") ?? .now
        let sharedAmount = MoneyAmount(amount: 19.99, currencyCode: "USD")

        let items = [
            RecurringItem(
                id: UUID(),
                title: "ChatGPT Plus",
                merchant: "ChatGPT Plus",
                category: "Productivity",
                symbolName: "sparkles.rectangle.stack",
                originalAmount: sharedAmount,
                homeAmount: sharedAmount,
                cadence: .monthly,
                nextDueDate: now,
                itemType: .expense,
                paymentMethodLabel: nil,
                reminder: .disabled,
                source: .chat,
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            RecurringItem(
                id: UUID(),
                title: "ChatGPT Plus",
                merchant: "ChatGPT Plus",
                category: "Productivity",
                symbolName: "sparkles.rectangle.stack",
                originalAmount: sharedAmount,
                homeAmount: sharedAmount,
                cadence: .monthly,
                nextDueDate: now,
                itemType: .expense,
                paymentMethodLabel: nil,
                reminder: .disabled,
                source: .manual,
                status: .active,
                createdAt: now,
                updatedAt: now
            )
        ]

        let insights = engine.generateInsights(
            items: items,
            monthAnchor: now,
            homeCurrencyCode: "USD",
            catalogService: catalog,
            aggregateStats: PersistedSession.empty.aggregateStats,
            allowAggregateLearning: true
        )

        XCTAssertTrue(insights.contains(where: { $0.title == "Potential duplicates" }))
    }
}

