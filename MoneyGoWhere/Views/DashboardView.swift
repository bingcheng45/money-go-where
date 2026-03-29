import Observation
import SwiftUI

struct DashboardView: View {
    @Bindable var model: AppModel

    private let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summarySection
                calendarSection
                itemsSection
                insightsSection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This month")
                .font(.title2.bold())

            HStack(spacing: 12) {
                summaryCard(title: "Income", amount: model.dashboardSummary.incomeTotal, tint: Color.green)
                summaryCard(title: "Expenses", amount: model.dashboardSummary.expenseTotal, tint: Color.red)
                summaryCard(title: "Net", amount: model.dashboardSummary.projectedNet, tint: Color.blue)
            }
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    model.previousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)

                Spacer()

                Text(model.selectedMonth.formattedMonthTitle())
                    .font(.headline)

                Spacer()

                Button {
                    model.nextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
            }

            VStack(spacing: 10) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(weekdaySymbols, id: \.self) { weekday in
                        Text(weekday.uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(calendarGrid, id: \.self) { date in
                        if let date {
                            CalendarDayCell(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: model.selectedDate),
                                occurrences: model.occurrenceGroups[Calendar.current.startOfDay(for: date)] ?? []
                            )
                            .onTapGesture {
                                model.selectedDate = Calendar.current.startOfDay(for: date)
                            }
                        } else {
                            Color.clear
                                .frame(height: 70)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recurring items")
                        .font(.title3.bold())
                    Text(model.selectedDate.formattedMonthDay())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    model.openEditor(for: nil)
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isReadOnly)
            }

            Picker("Filter", selection: $model.dashboardFilter) {
                ForEach(DashboardFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if model.filteredItems.isEmpty {
                ContentUnavailableView("No items for this view", systemImage: "tray", description: Text("Try another filter or add a recurring item to populate the calendar."))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(model.filteredItems) { item in
                    itemRow(item)
                }
            }
        }
    }

    private func itemRow(_ item: RecurringItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(item.title, systemImage: item.symbolName)
                    .font(.headline)
                Spacer()
                Text(item.originalAmount.formatted(localeIdentifier: model.session.profile.localeIdentifier))
                    .font(.headline)
                    .foregroundStyle(item.itemType == .income ? Color.green : Color.primary)
            }

            HStack {
                Text(item.category)
                Text("•")
                Text(item.cadence.displayTitle)
                Text("•")
                Text(item.nextDueDate.formattedMonthDay())
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let paymentMethod = item.paymentMethodLabel, !paymentMethod.isEmpty {
                Text(paymentMethod)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1), in: Capsule())
            }

            HStack {
                Button(item.status == .paused ? "Resume" : "Pause") {
                    model.pauseOrResume(item)
                }
                .buttonStyle(.bordered)
                .disabled(model.isReadOnly)

                Button("Edit") {
                    model.openEditor(for: item)
                }
                .buttonStyle(.bordered)
                .disabled(model.isReadOnly)

                Spacer()

                Button(role: .destructive) {
                    model.deleteItem(item)
                } label: {
                    Text("Delete")
                }
                .buttonStyle(.bordered)
                .disabled(model.isReadOnly)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.title3.bold())

            if model.insights.isEmpty {
                Text("Insights will appear once you have enough recurring items to analyze.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.insights) { insight in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(insight.title)
                            .font(.headline)
                        Text(insight.message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(toneColor(insight.tone), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(.bottom, 24)
    }

    private var calendarGrid: [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: model.selectedMonth) else {
            return []
        }
        let startOfMonth = monthInterval.start
        let days = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<2
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingSpaces = (firstWeekday - calendar.firstWeekday + 7) % 7

        var grid: [Date?] = Array(repeating: nil, count: leadingSpaces)
        for day in days {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                grid.append(date)
            }
        }
        while grid.count % 7 != 0 {
            grid.append(nil)
        }
        return grid
    }

    private func summaryCard(title: String, amount: MoneyAmount, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(amount.formatted(localeIdentifier: model.session.profile.localeIdentifier))
                .font(.headline.weight(.bold))
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [tint.opacity(0.18), tint.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private func toneColor(_ tone: InsightCard.Tone) -> Color {
        switch tone {
        case .neutral:
            Color(.systemBackground)
        case .positive:
            Color.green.opacity(0.12)
        case .caution:
            Color.orange.opacity(0.14)
        }
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let occurrences: [OccurrenceProjection]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(date.formatted(.dateTime.day()))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(occurrences.prefix(3)) { occurrence in
                    HStack(spacing: 4) {
                        Image(systemName: occurrence.symbolName)
                            .font(.caption2)
                        Text(occurrence.title)
                            .lineLimit(1)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : occurrence.itemType == .income ? Color.green : Color.primary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
        )
    }
}

