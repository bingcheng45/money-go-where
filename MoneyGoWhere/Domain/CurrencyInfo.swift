// Reusable currency metadata. Use CurrencyInfo.all for any currency picker in the app.
struct CurrencyInfo: Identifiable, Sendable {
    let code: String
    let symbol: String
    let name: String

    var id: String { code }
    var displayLabel: String { "\(name) - \(code)" }

    static func find(_ code: String) -> CurrencyInfo? {
        all.first { $0.code == code }
    }
}

extension CurrencyInfo {
    // ~50 major world currencies sorted by approximate global usage
    static let all: [CurrencyInfo] = [
        CurrencyInfo(code: "USD", symbol: "$",    name: "US Dollar"),
        CurrencyInfo(code: "EUR", symbol: "€",    name: "Euro"),
        CurrencyInfo(code: "GBP", symbol: "£",    name: "British Pound"),
        CurrencyInfo(code: "JPY", symbol: "¥",    name: "Japanese Yen"),
        CurrencyInfo(code: "SGD", symbol: "S$",   name: "Singapore Dollar"),
        CurrencyInfo(code: "AUD", symbol: "A$",   name: "Australian Dollar"),
        CurrencyInfo(code: "CAD", symbol: "C$",   name: "Canadian Dollar"),
        CurrencyInfo(code: "CHF", symbol: "CHF",  name: "Swiss Franc"),
        CurrencyInfo(code: "CNY", symbol: "¥",    name: "Chinese Yuan"),
        CurrencyInfo(code: "HKD", symbol: "HK$",  name: "Hong Kong Dollar"),
        CurrencyInfo(code: "KRW", symbol: "₩",    name: "South Korean Won"),
        CurrencyInfo(code: "INR", symbol: "₹",    name: "Indian Rupee"),
        CurrencyInfo(code: "MXN", symbol: "MX$",  name: "Mexican Peso"),
        CurrencyInfo(code: "BRL", symbol: "R$",   name: "Brazilian Real"),
        CurrencyInfo(code: "ZAR", symbol: "R",    name: "South African Rand"),
        CurrencyInfo(code: "NZD", symbol: "NZ$",  name: "New Zealand Dollar"),
        CurrencyInfo(code: "SEK", symbol: "kr",   name: "Swedish Krona"),
        CurrencyInfo(code: "NOK", symbol: "kr",   name: "Norwegian Krone"),
        CurrencyInfo(code: "DKK", symbol: "kr",   name: "Danish Krone"),
        CurrencyInfo(code: "THB", symbol: "฿",    name: "Thai Baht"),
        CurrencyInfo(code: "MYR", symbol: "RM",   name: "Malaysian Ringgit"),
        CurrencyInfo(code: "IDR", symbol: "Rp",   name: "Indonesian Rupiah"),
        CurrencyInfo(code: "PHP", symbol: "₱",    name: "Philippine Peso"),
        CurrencyInfo(code: "VND", symbol: "₫",    name: "Vietnamese Dong"),
        CurrencyInfo(code: "TWD", symbol: "NT$",  name: "Taiwan Dollar"),
        CurrencyInfo(code: "AED", symbol: "د.إ",  name: "UAE Dirham"),
        CurrencyInfo(code: "SAR", symbol: "﷼",    name: "Saudi Riyal"),
        CurrencyInfo(code: "QAR", symbol: "QR",   name: "Qatari Riyal"),
        CurrencyInfo(code: "KWD", symbol: "KD",   name: "Kuwaiti Dinar"),
        CurrencyInfo(code: "TRY", symbol: "₺",    name: "Turkish Lira"),
        CurrencyInfo(code: "RUB", symbol: "₽",    name: "Russian Ruble"),
        CurrencyInfo(code: "PLN", symbol: "zł",   name: "Polish Zloty"),
        CurrencyInfo(code: "ILS", symbol: "₪",    name: "Israeli Shekel"),
        CurrencyInfo(code: "UAH", symbol: "₴",    name: "Ukrainian Hryvnia"),
        CurrencyInfo(code: "CZK", symbol: "Kč",   name: "Czech Koruna"),
        CurrencyInfo(code: "HUF", symbol: "Ft",   name: "Hungarian Forint"),
        CurrencyInfo(code: "RON", symbol: "lei",  name: "Romanian Leu"),
        CurrencyInfo(code: "BGN", symbol: "лв",   name: "Bulgarian Lev"),
        CurrencyInfo(code: "PKR", symbol: "₨",    name: "Pakistani Rupee"),
        CurrencyInfo(code: "BDT", symbol: "৳",    name: "Bangladeshi Taka"),
        CurrencyInfo(code: "LKR", symbol: "Rs",   name: "Sri Lankan Rupee"),
        CurrencyInfo(code: "NGN", symbol: "₦",    name: "Nigerian Naira"),
        CurrencyInfo(code: "EGP", symbol: "£",    name: "Egyptian Pound"),
        CurrencyInfo(code: "KES", symbol: "KSh",  name: "Kenyan Shilling"),
        CurrencyInfo(code: "GHS", symbol: "₵",    name: "Ghanaian Cedi"),
        CurrencyInfo(code: "MAD", symbol: "MAD",  name: "Moroccan Dirham"),
        CurrencyInfo(code: "CLP", symbol: "CL$",  name: "Chilean Peso"),
        CurrencyInfo(code: "COP", symbol: "CO$",  name: "Colombian Peso"),
        CurrencyInfo(code: "PEN", symbol: "S/",   name: "Peruvian Sol"),
        CurrencyInfo(code: "ARS", symbol: "AR$",  name: "Argentine Peso"),
    ]
}
