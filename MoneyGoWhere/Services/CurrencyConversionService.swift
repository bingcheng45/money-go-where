import Foundation

struct CurrencyConversionService {
    let referenceDate: Date
    private let usdPerUnit: [String: Decimal]

    init(referenceDate: Date = .now) {
        self.referenceDate = referenceDate
        usdPerUnit = [
            "USD": 1,
            "SGD": 0.74,
            "EUR": 1.09,
            "GBP": 1.28,
            "JPY": 0.0067
        ]
    }

    func convert(_ amount: MoneyAmount, to currencyCode: String) -> MoneyAmount {
        guard amount.currencyCode != currencyCode else {
            return amount
        }
        guard
            let fromRate = usdPerUnit[amount.currencyCode],
            let toRate = usdPerUnit[currencyCode]
        else {
            return MoneyAmount(amount: amount.amount, currencyCode: currencyCode)
        }

        let usdValue = amount.amount * fromRate
        let converted = usdValue / toRate
        return MoneyAmount(amount: converted.rounded(scale: 2), currencyCode: currencyCode)
    }
}

private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var original = self
        var result = Decimal()
        NSDecimalRound(&result, &original, scale, .bankers)
        return result
    }
}
