import Foundation

struct InsightsEngine {
    let projectionEngine = ProjectionEngine()

    func generateInsights(
        items: [RecurringItem],
        monthAnchor: Date,
        homeCurrencyCode: String,
        catalogService: CatalogService,
        aggregateStats: AggregateStats,
        allowAggregateLearning: Bool,
        calendar: Calendar = .current
    ) -> [InsightCard] {
        var insights: [InsightCard] = []
        let activeItems = items.filter { $0.status == .active }

        let duplicates = Dictionary(grouping: activeItems) { $0.title.normalizedToken }
            .filter { $1.count > 1 }
        if let duplicateGroup = duplicates.first?.value {
            let titles = duplicateGroup.map(\.title).joined(separator: ", ")
            insights.append(
                InsightCard(
                    id: UUID(),
                    title: "Potential duplicates",
                    message: "You have overlapping recurring items for \(titles). Review them to avoid double counting.",
                    tone: .caution
                )
            )
        }

        let groupedByCategory = Dictionary(grouping: activeItems.filter { $0.itemType == .expense }) { $0.category }
        if let crowdedCategory = groupedByCategory.first(where: { $0.value.count >= 3 }) {
            let total = crowdedCategory.value.map(\.homeAmount.amount).sum()
            let totalMoney = MoneyAmount(amount: total, currencyCode: homeCurrencyCode)
            insights.append(
                InsightCard(
                    id: UUID(),
                    title: "Category concentration",
                    message: "\(crowdedCategory.key) is taking \(totalMoney.formatted()) this cycle. Consolidating services here could improve your net cashflow.",
                    tone: .neutral
                )
            )
        }

        let upcoming = projectionEngine.groupedOccurrences(for: activeItems, in: monthAnchor, calendar: calendar)
            .mapValues { $0.filter { $0.itemType == .expense } }
            .filter { !$0.value.isEmpty }
        if let heaviestDay = upcoming.max(by: {
            $0.value.map(\.homeAmount.amount).sum() < $1.value.map(\.homeAmount.amount).sum()
        }) {
            let total = heaviestDay.value.map(\.homeAmount.amount).sum()
            let totalMoney = MoneyAmount(amount: total, currencyCode: homeCurrencyCode)
            insights.append(
                InsightCard(
                    id: UUID(),
                    title: "Heaviest spend day",
                    message: "\(heaviestDay.key.formattedMonthDay()) carries about \(totalMoney.formatted()). You may want extra buffer before that date.",
                    tone: .caution
                )
            )
        }

        if allowAggregateLearning {
            let suggestions = catalogService.suggestions(excluding: activeItems, aggregateStats: aggregateStats)
            if let suggestion = suggestions.first {
                let popularity = aggregateStats.merchantPopularity[suggestion.title] ?? suggestion.popularity
                insights.append(
                    InsightCard(
                        id: UUID(),
                        title: "Popular benchmark",
                        message: "\(suggestion.title) appears frequently in aggregate user data. Use it as a benchmark if you are comparing similar services.",
                        tone: .positive
                    )
                )
                if popularity > 80 {
                    insights.append(
                        InsightCard(
                            id: UUID(),
                            title: "Autofill confidence",
                            message: "Autofill defaults for \(suggestion.title) are backed by strong popularity signals, which makes future manual entry faster.",
                            tone: .neutral
                        )
                    )
                }
            }
        }

        return Array(insights.prefix(4))
    }
}

