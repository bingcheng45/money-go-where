// Common payment method options for dropdowns. The empty string represents "None".
enum PaymentMethodOption {
    static let all: [String] = [
        "",               // None (default)
        "Cash",
        "Free",
        "Credit Card",
        "Visa Card",
        "Mastercard",
        "American Express",
        "Debit Card",
        "Bank Transfer",
        "GIRO",
        "Cheque",
        "PayNow",
        "PayLah!",
        "GrabPay",
        "Shopee Pay",
        "WeChat Pay",
        "Alipay",
        "Apple Pay",
        "Google Pay",
        "PayPal",
        "Venmo",
        "Zelle",
        "Crypto",
        "Gift Card",
        "BNPL (Afterpay / Klarna)",
    ]

    static func displayName(for value: String) -> String {
        value.isEmpty ? "None" : value
    }
}
