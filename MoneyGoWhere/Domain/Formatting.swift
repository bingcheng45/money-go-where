import Foundation

extension Decimal {
    var asNSNumber: NSNumber {
        NSDecimalNumber(decimal: self)
    }
}

extension MoneyAmount {
    func formatted(localeIdentifier: String? = nil) -> String {
        let locale = localeIdentifier.map(Locale.init(identifier:)) ?? Locale.current
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        return formatter.string(from: amount.asNSNumber) ?? "\(currencyCode) \(amount)"
    }
}

extension Date {
    func formattedMonthDay() -> String {
        formatted(.dateTime.month(.abbreviated).day())
    }

    func formattedMonthTitle() -> String {
        formatted(.dateTime.month(.wide).year())
    }
}

extension String {
    var normalizedToken: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Collection where Element == Decimal {
    func sum() -> Decimal {
        reduce(.zero, +)
    }
}

