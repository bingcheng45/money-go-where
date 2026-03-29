import Foundation

struct ProjectionEngine {
    func occurrences(for item: RecurringItem, in monthAnchor: Date, calendar: Calendar = .current) -> [OccurrenceProjection] {
        guard item.status == .active else {
            return []
        }

        let monthInterval = calendar.dateInterval(of: .month, for: monthAnchor) ?? DateInterval(start: monthAnchor, duration: 60 * 60 * 24 * 30)
        var date = item.nextDueDate

        while date < monthInterval.start {
            guard let advanced = advance(date: date, cadence: item.cadence, calendar: calendar) else {
                break
            }
            date = advanced
        }

        var projections: [OccurrenceProjection] = []
        while date < monthInterval.end {
            let projection = OccurrenceProjection(
                id: "\(item.id.uuidString)-\(date.timeIntervalSince1970)",
                itemID: item.id,
                title: item.title,
                symbolName: item.symbolName,
                itemType: item.itemType,
                originalAmount: item.originalAmount,
                homeAmount: item.homeAmount,
                date: date
            )
            projections.append(projection)

            guard let advanced = advance(date: date, cadence: item.cadence, calendar: calendar) else {
                break
            }
            date = advanced
        }

        return projections
    }

    func groupedOccurrences(for items: [RecurringItem], in monthAnchor: Date, calendar: Calendar = .current) -> [Date: [OccurrenceProjection]] {
        let all = items.flatMap { occurrences(for: $0, in: monthAnchor, calendar: calendar) }
        return Dictionary(grouping: all) { calendar.startOfDay(for: $0.date) }
    }

    func summary(for items: [RecurringItem], in homeCurrencyCode: String, monthAnchor: Date, calendar: Calendar = .current) -> DashboardSummary {
        let projections = items.flatMap { occurrences(for: $0, in: monthAnchor, calendar: calendar) }
        let incomes = projections
            .filter { $0.itemType == .income }
            .map(\.homeAmount.amount)
            .sum()
        let expenses = projections
            .filter { $0.itemType == .expense }
            .map(\.homeAmount.amount)
            .sum()

        return DashboardSummary(
            incomeTotal: MoneyAmount(amount: incomes, currencyCode: homeCurrencyCode),
            expenseTotal: MoneyAmount(amount: expenses, currencyCode: homeCurrencyCode),
            projectedNet: MoneyAmount(amount: incomes - expenses, currencyCode: homeCurrencyCode)
        )
    }

    private func advance(date: Date, cadence: RecurrenceCadence, calendar: Calendar) -> Date? {
        switch cadence {
        case .daily:
            calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}

