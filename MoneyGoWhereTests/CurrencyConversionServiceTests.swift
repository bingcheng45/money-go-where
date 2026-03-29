import XCTest
@testable import MoneyGoWhere

final class CurrencyConversionServiceTests: XCTestCase {
    func testReferenceConversionProducesRoundedMoney() {
        let service = CurrencyConversionService()
        let input = MoneyAmount(amount: 20, currencyCode: "USD")

        let converted = service.convert(input, to: "SGD")

        XCTAssertEqual(converted.currencyCode, "SGD")
        XCTAssertEqual(converted.amount, Decimal(string: "27.03"))
    }
}

