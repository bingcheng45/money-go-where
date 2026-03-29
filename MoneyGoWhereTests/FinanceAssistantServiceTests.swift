import XCTest
@testable import MoneyGoWhere

final class FinanceAssistantServiceTests: XCTestCase {
    func testChatGPTDefaultsToCatalogPricing() {
        let service = FinanceAssistantService()
        var profile = UserProfile.empty
        profile.defaultCurrencyCode = "USD"

        let result = service.handleUserMessage("Track ChatGPT monthly on the 15th", existingDraft: nil, profile: profile, memories: [])

        XCTAssertEqual(result.pendingDraft?.title, "ChatGPT Plus")
        XCTAssertEqual(result.pendingDraft?.amount?.currencyCode, "USD")
        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "20"))
        XCTAssertEqual(result.pendingDraft?.cadence, .monthly)
        XCTAssertTrue(result.pendingDraft?.readyForConfirmation == true)
    }

    func testMissingAmountPromptsForAmount() {
        let service = FinanceAssistantService()
        var profile = UserProfile.empty
        profile.defaultCurrencyCode = "USD"

        let result = service.handleUserMessage("Salary on the 28th monthly", existingDraft: nil, profile: profile, memories: [])

        XCTAssertEqual(result.pendingDraft?.itemType, .income)
        XCTAssertFalse(result.pendingDraft?.readyForConfirmation ?? true)
        XCTAssertEqual(result.pendingDraft?.missingFields.first, .amount)
        XCTAssertEqual(result.assistantMessage.body, DraftField.amount.question)
    }
}

