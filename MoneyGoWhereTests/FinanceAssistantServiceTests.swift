import XCTest
@testable import MoneyGoWhere

final class FinanceAssistantServiceTests: XCTestCase {

    // MARK: - Helpers

    private var service: FinanceAssistantService { FinanceAssistantService() }

    private var usdProfile: UserProfile {
        var p = UserProfile.empty
        p.defaultCurrencyCode = "USD"
        return p
    }

    private var sgdProfile: UserProfile {
        var p = UserProfile.empty
        p.defaultCurrencyCode = "SGD"
        return p
    }

    // MARK: - Existing Tests

    func testChatGPTDefaultsToCatalogPricing() {
        let result = service.handleUserMessage("Track ChatGPT monthly on the 15th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.title, "ChatGPT Plus")
        XCTAssertEqual(result.pendingDraft?.amount?.currencyCode, "USD")
        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "20"))
        XCTAssertEqual(result.pendingDraft?.cadence, .monthly)
        XCTAssertTrue(result.pendingDraft?.readyForConfirmation == true)
    }

    func testMissingAmountPromptsForAmount() {
        let result = service.handleUserMessage("Salary on the 28th monthly", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.itemType, .income)
        XCTAssertFalse(result.pendingDraft?.readyForConfirmation ?? true)
        XCTAssertEqual(result.pendingDraft?.missingFields.first, .amount)
        XCTAssertEqual(result.assistantMessage.body, DraftField.amount.question)
    }

    func testNetflixExtractsCompleteItem() {
        let result = service.handleUserMessage("Netflix $15.99 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        let draft = result.pendingDraft
        XCTAssertNotNil(draft)
        XCTAssertTrue(draft?.title?.lowercased().contains("netflix") == true)
        XCTAssertEqual(draft?.amount?.amount, Decimal(string: "15.99"))
        XCTAssertEqual(draft?.cadence, .monthly)
        XCTAssertNotNil(draft?.nextDueDate)
        XCTAssertTrue(draft?.readyForConfirmation == true)
    }

    func testYearlyCadenceDetected() {
        let result = service.handleUserMessage("Spotify Premium $99 yearly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.cadence, .yearly)
    }

    func testWeeklyCadenceDetected() {
        let result = service.handleUserMessage("gym $50 weekly on Mondays", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.cadence, .weekly)
    }

    func testIncomeItemType() {
        let result = service.handleUserMessage("Salary $5000 monthly on the 28th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.itemType, .income)
        XCTAssertTrue(result.pendingDraft?.readyForConfirmation == true)
    }

    func testMissingCadencePromptsForCadence() {
        let result = service.handleUserMessage("rent $1200 on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertFalse(result.pendingDraft?.readyForConfirmation ?? true)
        XCTAssertTrue(result.pendingDraft?.missingFields.contains(.cadence) == true)
    }

    func testMissingDatePromptsForDate() {
        let result = service.handleUserMessage("Spotify $9.99 monthly", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertFalse(result.pendingDraft?.readyForConfirmation ?? true)
        XCTAssertTrue(result.pendingDraft?.missingFields.contains(.nextDueDate) == true)
    }

    func testMultiTurnClarificationCompletesItem() {
        let turn1 = service.handleUserMessage("gym membership monthly", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertFalse(turn1.pendingDraft?.readyForConfirmation ?? true)

        let turn2 = service.handleUserMessage("$80 on the 5th", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])

        XCTAssertTrue(turn2.pendingDraft?.readyForConfirmation == true)
        XCTAssertEqual(turn2.pendingDraft?.amount?.amount, Decimal(string: "80"))
    }

    func testEuroCurrencyExtracted() {
        let result = service.handleUserMessage("Netflix €14.99 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.currencyCode, "EUR")
        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "14.99"))
    }

    func testAmountOverridesCatalogDefault() {
        let result = service.handleUserMessage("ChatGPT $25 monthly on the 15th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "25"))
    }

    func testFreeItemRequiresExplicitAmount() {
        let result = service.handleUserMessage("free gym membership monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        let draft = result.pendingDraft
        let isZeroOrMissing = draft?.amount == nil || draft?.amount?.amount == 0
        if isZeroOrMissing {
            XCTAssertFalse(draft?.readyForConfirmation ?? true)
        }
    }

    // MARK: - Group 1: Amount decimal precision

    func testAmountOneDecimalPlace() {
        let result = service.handleUserMessage("gym $9.9 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "9.9"))
        XCTAssertTrue(result.pendingDraft?.readyForConfirmation == true)
    }

    func testAmountTwoDecimalPlaces() {
        let result = service.handleUserMessage("gym $9.90 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        // Decimal("9.90") and Decimal("9.9") are equal
        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "9.90"))
        XCTAssertTrue(result.pendingDraft?.readyForConfirmation == true)
    }

    func testAmountThreeDecimalsClampedToTwo() {
        // Regex \d{1,2} captures at most 2 decimal digits, so $15.999 → 15.99
        let result = service.handleUserMessage("gym $15.999 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "15.99"))
    }

    func testLeadingDecimalParsedAsInteger() {
        // Known behaviour: ".30" has no leading digit so the regex skips the ".",
        // then matches "30" as a plain integer → amount = 30, not 0.30 or nil.
        let result = service.handleUserMessage("gym .30 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "30"),
                       "Leading-decimal '.30' is parsed as integer 30, not 0.30 — known regex limitation")
    }

    func testZeroDollarCentsOnlyAmount() {
        // $0.99 is a valid non-zero amount
        let result = service.handleUserMessage("gym $0.99 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "0.99"))
        XCTAssertTrue(result.pendingDraft?.readyForConfirmation == true)
    }

    func testCommaFormattedAmountKnownLimitation() {
        // Known limitation: regex stops at comma, so $1,200 matches "1" not "1200"
        // This test documents the actual behaviour — not the desired behaviour.
        let result = service.handleUserMessage("rent $1,200 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        let amount = result.pendingDraft?.amount?.amount
        // Either amount is missing (nil) or incorrectly parsed as 1
        if let amount {
            XCTAssertNotEqual(amount, Decimal(string: "1200"), "Comma-formatted amounts are a known regex limitation — $1,200 is not parsed as 1200")
        } else {
            XCTAssertTrue(result.pendingDraft?.missingFields.contains(.amount) == true)
        }
    }

    // MARK: - Group 2: Currency symbol & code detection

    func testSGDCurrencyCodeRecognised() {
        let result = service.handleUserMessage("Netflix SGD 14.99 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.currencyCode, "SGD")
    }

    func testUSDCodeOverridesSGDDefault() {
        let result = service.handleUserMessage("gym USD 50 monthly on the 1st", existingDraft: nil, profile: sgdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.currencyCode, "USD")
    }

    func testGBPSymbolRecognised() {
        let result = service.handleUserMessage("Netflix £14.99 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.currencyCode, "GBP")
        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "14.99"))
    }

    func testJPYSymbolRecognised() {
        let result = service.handleUserMessage("gym ¥1500 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.currencyCode, "JPY")
        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "1500"))
    }

    func testNoSymbolFallsBackToProfileCurrency() {
        // No currency symbol or code — should use sgdProfile's default
        let result = service.handleUserMessage("gym 50 monthly on the 1st", existingDraft: nil, profile: sgdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.currencyCode, "SGD")
    }

    func testCurrencyCodeAfterAmountUsesDefaultKnownLimitation() {
        // Known limitation: regex only detects currency code BEFORE the amount.
        // "14.99 EUR" → EUR is not captured; falls back to profile default (USD).
        let result = service.handleUserMessage("Netflix 14.99 EUR monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.currencyCode, "USD",
                       "Known limitation: currency code after amount is not detected by the regex")
    }

    // MARK: - Group 3: Cadence keyword variants

    func testAnnuallyCadenceDetected() {
        let result = service.handleUserMessage("Spotify $99 annually on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.cadence, .yearly)
    }

    func testAnnualCadenceDetected() {
        let result = service.handleUserMessage("Adobe $60 annual on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.cadence, .yearly)
    }

    func testEveryMonthCadenceDetected() {
        let result = service.handleUserMessage("gym $50 every month on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.cadence, .monthly)
    }

    func testSlashMoCadenceDetected() {
        let result = service.handleUserMessage("gym $50 /mo on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.cadence, .monthly)
    }

    func testEveryWeekCadenceDetected() {
        let result = service.handleUserMessage("gym $50 every week on Mondays", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.cadence, .weekly)
    }

    func testEveryDayCadenceDetected() {
        let result = service.handleUserMessage("coffee $5 every day", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.cadence, .daily)
    }

    func testDailyCadenceDetected() {
        let result = service.handleUserMessage("coffee $5 daily", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.cadence, .daily)
    }

    func testCadenceTypoLeavesFieldMissing() {
        // "monthy" is not a recognised keyword — cadence should be nil
        let result = service.handleUserMessage("gym $50 monthy on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertTrue(result.pendingDraft?.missingFields.contains(.cadence) == true)
    }

    // MARK: - Group 4: Field ordering variations

    func testDateFirstFieldOrder() {
        let result = service.handleUserMessage("on the 1st monthly $15.99 Netflix", existingDraft: nil, profile: usdProfile, memories: [])

        let draft = result.pendingDraft
        XCTAssertTrue(draft?.title?.lowercased().contains("netflix") == true)
        XCTAssertEqual(draft?.amount?.amount, Decimal(string: "15.99"))
        XCTAssertEqual(draft?.cadence, .monthly)
        XCTAssertNotNil(draft?.nextDueDate)
        XCTAssertTrue(draft?.readyForConfirmation == true)
    }

    func testAmountLastFieldOrder() {
        let result = service.handleUserMessage("Netflix monthly on the 1st $15.99", existingDraft: nil, profile: usdProfile, memories: [])

        let draft = result.pendingDraft
        XCTAssertTrue(draft?.title?.lowercased().contains("netflix") == true)
        XCTAssertEqual(draft?.amount?.amount, Decimal(string: "15.99"))
        XCTAssertEqual(draft?.cadence, .monthly)
        XCTAssertNotNil(draft?.nextDueDate)
        XCTAssertTrue(draft?.readyForConfirmation == true)
    }

    func testCadenceFirstFieldOrder() {
        let result = service.handleUserMessage("monthly Netflix $15.99 on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        let draft = result.pendingDraft
        XCTAssertTrue(draft?.title?.lowercased().contains("netflix") == true)
        XCTAssertEqual(draft?.amount?.amount, Decimal(string: "15.99"))
        XCTAssertEqual(draft?.cadence, .monthly)
        XCTAssertNotNil(draft?.nextDueDate)
        XCTAssertTrue(draft?.readyForConfirmation == true)
    }

    // MARK: - Group 5: Multi-turn clarification flows

    func testThreeTurnFlow() {
        // T1: title + cadence only
        let turn1 = service.handleUserMessage("gym membership monthly", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertFalse(turn1.pendingDraft?.readyForConfirmation ?? true)

        // T2: add amount
        let turn2 = service.handleUserMessage("$80", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertFalse(turn2.pendingDraft?.readyForConfirmation ?? true)
        XCTAssertEqual(turn2.pendingDraft?.amount?.amount, Decimal(string: "80"))

        // T3: add date — should now be complete
        let turn3 = service.handleUserMessage("on the 5th", existingDraft: turn2.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertTrue(turn3.pendingDraft?.readyForConfirmation == true)
        XCTAssertEqual(turn3.pendingDraft?.cadence, .monthly)
        XCTAssertEqual(turn3.pendingDraft?.amount?.amount, Decimal(string: "80"))
        XCTAssertNotNil(turn3.pendingDraft?.nextDueDate)
    }

    func testPureAmountCadenceDateInfersTitleFromTokens() {
        // inferTitle keeps non-keyword tokens — "50 5th" are left after stripping "$", "monthly", "on", "the"
        // So title IS inferred; the item becomes ready without an explicit name.
        let result = service.handleUserMessage("$50 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertNotNil(result.pendingDraft?.title)
        XCTAssertFalse(result.pendingDraft?.title?.isEmpty ?? true)
        XCTAssertTrue(result.pendingDraft?.readyForConfirmation == true,
                      "Title is inferred from remaining numeric tokens — item should be ready")
    }

    func testMissingCadenceCompletedInTurnTwo() {
        // T1: title + amount + date, no cadence → not ready
        let turn1 = service.handleUserMessage("gym $50 on the 5th", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertFalse(turn1.pendingDraft?.readyForConfirmation ?? true)
        XCTAssertTrue(turn1.pendingDraft?.missingFields.contains(.cadence) == true)

        // T2: provide cadence → ready
        let turn2 = service.handleUserMessage("monthly", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertTrue(turn2.pendingDraft?.readyForConfirmation == true)
        XCTAssertEqual(turn2.pendingDraft?.cadence, .monthly)
    }

    func testMultiTurnAmountOverridesEarlierAmount() {
        // T1: gym with $80
        let turn1 = service.handleUserMessage("gym $80 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertEqual(turn1.pendingDraft?.amount?.amount, Decimal(string: "80"))

        // T2: correct to $90
        let turn2 = service.handleUserMessage("actually $90", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertEqual(turn2.pendingDraft?.amount?.amount, Decimal(string: "90"))
    }

    // MARK: - Group 6: Income keyword variants

    func testFreelanceKeywordDetectsIncome() {
        let result = service.handleUserMessage("freelance work $2000 monthly on the 15th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.itemType, .income)
    }

    func testBonusKeywordDetectsIncome() {
        let result = service.handleUserMessage("bonus $500 monthly on the 28th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.itemType, .income)
    }

    func testPaycheckKeywordDetectsIncome() {
        let result = service.handleUserMessage("paycheck $3000 monthly on the 15th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.itemType, .income)
    }

    func testNoHintDefaultsToExpense() {
        // No income or expense keywords — should default to expense
        let result = service.handleUserMessage("gym $50 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.itemType, .expense)
    }

    func testBillKeywordDetectsExpense() {
        let result = service.handleUserMessage("electricity bill $80 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.itemType, .expense)
    }

    // MARK: - Group 7: Catalog defaults & overrides

    func testNetflixAloneProvidesCatalogDefaults() {
        // Catalog provides title + amount + cadence, but NOT date → not ready
        let result = service.handleUserMessage("Netflix", existingDraft: nil, profile: usdProfile, memories: [])

        let draft = result.pendingDraft
        XCTAssertTrue(draft?.title?.lowercased().contains("netflix") == true)
        XCTAssertNotNil(draft?.amount)
        XCTAssertEqual(draft?.cadence, .monthly)
        XCTAssertFalse(draft?.readyForConfirmation ?? true)
        XCTAssertTrue(draft?.missingFields.contains(.nextDueDate) == true)
    }

    func testSpotifyAmountOverridesCatalogDefault() {
        // Catalog default for Spotify is $11.99; user says $9.99
        let result = service.handleUserMessage("Spotify $9.99 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "9.99"))
    }

    func testCatalogMatchCaseInsensitive() {
        // Lowercase "netflix" should still hit the catalog entry
        let result = service.handleUserMessage("netflix $15.99 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertTrue(result.pendingDraft?.title?.lowercased().contains("netflix") == true)
        XCTAssertTrue(result.pendingDraft?.readyForConfirmation == true)
    }

    // MARK: - Group 8: Typos & catalog misses

    func testTypoInTitleNoCatalogMatch() {
        // "Netflx" won't match catalog — title should still be inferred and item complete
        let result = service.handleUserMessage("Netflx $15.99 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        let draft = result.pendingDraft
        XCTAssertNotNil(draft?.title)
        XCTAssertEqual(draft?.amount?.amount, Decimal(string: "15.99"))
        XCTAssertTrue(draft?.readyForConfirmation == true)
    }

    func testCadenceTypoInOtherwiseCompleteMessage() {
        // "monthy" is not recognised — even with all other fields present, cadence is missing.
        // Use a non-catalog title so the catalog cannot supply the cadence.
        let result = service.handleUserMessage("MyService $15.99 monthy on the 1st", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertTrue(result.pendingDraft?.missingFields.contains(.cadence) == true)
        XCTAssertFalse(result.pendingDraft?.readyForConfirmation ?? true)
    }

    // MARK: - Group 9: Missing field combinations

    func testMissingAmountAndDateBothReported() {
        // Title (inferred) and cadence present, but amount and date missing
        let result = service.handleUserMessage("gym membership monthly", existingDraft: nil, profile: usdProfile, memories: [])

        let missing = result.pendingDraft?.missingFields ?? []
        XCTAssertTrue(missing.contains(.amount))
        XCTAssertTrue(missing.contains(.nextDueDate))
    }

    func testFirstPromptedFieldIsAmount() {
        // Validation order: title → amount → cadence → nextDueDate → itemType
        // Title is inferred from "gym membership", cadence is present — so first missing = amount
        let result = service.handleUserMessage("gym membership monthly", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.missingFields.first, .amount)
    }

    func testAllFieldsProvidedNoMissingFields() {
        let result = service.handleUserMessage("gym $50 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertTrue(result.pendingDraft?.missingFields.isEmpty == true)
        XCTAssertTrue(result.pendingDraft?.readyForConfirmation == true)
    }

    // MARK: - Bug Regressions: bare number date response

    // Goal: salary income $7500/month due on the 28th
    // Bug: replying "28" to the date prompt overwrote amount ($7500→$28), title ("Salary"→"28"),
    //      and item type (income→expense).

    func testBareNumberDateResponseSetsDatePreservesAmount() {
        // T1: establish salary with amount and cadence
        let turn1 = service.handleUserMessage("salary $7500 monthly", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertEqual(turn1.pendingDraft?.amount?.amount, Decimal(string: "7500"))
        XCTAssertTrue(turn1.pendingDraft?.missingFields.contains(.nextDueDate) == true)

        // T2: bare day number — should set date, NOT clobber amount
        let turn2 = service.handleUserMessage("28", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertEqual(turn2.pendingDraft?.amount?.amount, Decimal(string: "7500"),
                       "Bare number '28' replied to a date prompt should not overwrite the existing amount")
        XCTAssertNotNil(turn2.pendingDraft?.nextDueDate, "'28' should be treated as day-of-month")
        XCTAssertTrue(turn2.pendingDraft?.readyForConfirmation == true)
    }

    func testBareNumberDateResponsePreservesTitle() {
        let turn1 = service.handleUserMessage("salary $7500 monthly", existingDraft: nil, profile: usdProfile, memories: [])
        let turn2 = service.handleUserMessage("28", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])

        XCTAssertFalse(turn2.pendingDraft?.title == "28",
                       "Bare number '28' should not replace the existing title with a numeric string")
        XCTAssertTrue(turn2.pendingDraft?.title?.lowercased().contains("salary") == true)
    }

    func testBareNumberDateResponsePreservesIncomeType() {
        let turn1 = service.handleUserMessage("salary $7500 monthly", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertEqual(turn1.pendingDraft?.itemType, .income)

        let turn2 = service.handleUserMessage("28", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertEqual(turn2.pendingDraft?.itemType, .income,
                       "Income type must not be overwritten by the .expense default when replying with a bare number")
    }

    func testSmallBareNumberDateResponsePreservesAmount() {
        // Same bug with a small amount-like date (5) — could easily be misread as $5
        // Goal: gym $80/month on the 5th
        let turn1 = service.handleUserMessage("gym $80 monthly", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertEqual(turn1.pendingDraft?.amount?.amount, Decimal(string: "80"))

        let turn2 = service.handleUserMessage("5", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertEqual(turn2.pendingDraft?.amount?.amount, Decimal(string: "80"),
                       "Bare number '5' should set the date, not overwrite the $80 amount")
        XCTAssertNotNil(turn2.pendingDraft?.nextDueDate)
        XCTAssertTrue(turn2.pendingDraft?.readyForConfirmation == true)
    }

    // MARK: - Bug Regressions: NSDataDetector false positive on "a mon"

    // Goal: salary $500/month — "a mon" abbreviation must NOT produce a phantom date
    // Bug: NSDataDetector interprets "mon" as next Monday and sets nextDueDate.

    func testCadenceAbbreviationAMonDoesNotProducePhantomDate() {
        let result = service.handleUserMessage("salary 500 a mon", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertNil(result.pendingDraft?.nextDueDate,
                     "'a mon' (informal 'a month') must not be parsed as next Monday by NSDataDetector")
        XCTAssertTrue(result.pendingDraft?.missingFields.contains(.nextDueDate) == true)
        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "500"))
    }

    // MARK: - Multi-turn complete flows

    // Goal: salary income $7500/month on the 28th — 3-turn natural conversation
    func testSalaryMultiTurnThreeSteps() {
        // T1: title + cadence
        let turn1 = service.handleUserMessage("salary monthly", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertEqual(turn1.pendingDraft?.itemType, .income)
        XCTAssertEqual(turn1.pendingDraft?.cadence, .monthly)
        XCTAssertTrue(turn1.pendingDraft?.missingFields.contains(.amount) == true)

        // T2: provide amount
        let turn2 = service.handleUserMessage("$7500", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertEqual(turn2.pendingDraft?.amount?.amount, Decimal(string: "7500"))
        XCTAssertTrue(turn2.pendingDraft?.missingFields.contains(.nextDueDate) == true)

        // T3: provide date using ordinal suffix
        let turn3 = service.handleUserMessage("28th", existingDraft: turn2.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertTrue(turn3.pendingDraft?.readyForConfirmation == true)
        XCTAssertNotNil(turn3.pendingDraft?.nextDueDate)
        XCTAssertEqual(turn3.pendingDraft?.amount?.amount, Decimal(string: "7500"))
        XCTAssertEqual(turn3.pendingDraft?.itemType, .income)
    }

    // Goal: salary income $7500/month on the 28th — using bare number on the final turn
    func testSalaryMultiTurnBareNumberFinalStep() {
        let turn1 = service.handleUserMessage("salary monthly", existingDraft: nil, profile: usdProfile, memories: [])
        let turn2 = service.handleUserMessage("$7500", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])

        let turn3 = service.handleUserMessage("28", existingDraft: turn2.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertTrue(turn3.pendingDraft?.readyForConfirmation == true)
        XCTAssertEqual(turn3.pendingDraft?.amount?.amount, Decimal(string: "7500"),
                       "Bare '28' on the last turn must set the date not overwrite the amount")
        XCTAssertEqual(turn3.pendingDraft?.itemType, .income)
    }

    // Goal: salary $7500/month — "a month" informal cadence still works via catalog lookup
    func testSalaryWithAMonthInformalCadence() {
        // Catalog provides monthly cadence for "salary"; "a month" is informal but catalog saves it.
        let result = service.handleUserMessage("salary 7500 a month", existingDraft: nil, profile: usdProfile, memories: [])

        XCTAssertEqual(result.pendingDraft?.amount?.amount, Decimal(string: "7500"))
        XCTAssertEqual(result.pendingDraft?.itemType, .income)
        XCTAssertEqual(result.pendingDraft?.cadence, .monthly, "Salary catalog supplies monthly cadence")
        XCTAssertFalse(result.pendingDraft?.missingFields.contains(.amount) == true)
        XCTAssertFalse(result.pendingDraft?.missingFields.contains(.cadence) == true)
        XCTAssertTrue(result.pendingDraft?.missingFields.contains(.nextDueDate) == true)
    }

    // Goal: Netflix $15.99/month on the 1st — catalog item completed with bare ordinal date
    func testNetflixCatalogDateCompletedWithOrdinalResponse() {
        let turn1 = service.handleUserMessage("Netflix", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertTrue(turn1.pendingDraft?.title?.lowercased().contains("netflix") == true)
        XCTAssertNotNil(turn1.pendingDraft?.amount)
        XCTAssertEqual(turn1.pendingDraft?.cadence, .monthly)
        XCTAssertTrue(turn1.pendingDraft?.missingFields.contains(.nextDueDate) == true)

        let turn2 = service.handleUserMessage("1st", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertTrue(turn2.pendingDraft?.readyForConfirmation == true)
        XCTAssertNotNil(turn2.pendingDraft?.nextDueDate)
    }

    // Goal: electricity bill $80/month on the 5th — cadence + date in same follow-up
    func testElectricityBillCompletedInTwoTurns() {
        let turn1 = service.handleUserMessage("electricity bill $80", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertEqual(turn1.pendingDraft?.itemType, .expense)
        XCTAssertEqual(turn1.pendingDraft?.amount?.amount, Decimal(string: "80"))
        XCTAssertTrue(turn1.pendingDraft?.missingFields.contains(.cadence) == true)

        let turn2 = service.handleUserMessage("monthly on the 5th", existingDraft: turn1.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertTrue(turn2.pendingDraft?.readyForConfirmation == true)
        XCTAssertEqual(turn2.pendingDraft?.cadence, .monthly)
        XCTAssertNotNil(turn2.pendingDraft?.nextDueDate)
        XCTAssertEqual(turn2.pendingDraft?.itemType, .expense)
        XCTAssertEqual(turn2.pendingDraft?.amount?.amount, Decimal(string: "80"))
    }

    // MARK: - Post-ready prompts: corrections and noise on a complete draft

    // Amount correction on an already-ready draft — should update amount and stay ready.
    func testAmountCorrectionOnReadyDraft() {
        let ready = service.handleUserMessage("gym $80 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertTrue(ready.pendingDraft?.readyForConfirmation == true)

        let corrected = service.handleUserMessage("actually $90", existingDraft: ready.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertEqual(corrected.pendingDraft?.amount?.amount, Decimal(string: "90"))
        XCTAssertTrue(corrected.pendingDraft?.readyForConfirmation == true,
                      "Draft should remain ready after correcting a single field")
    }

    // Date correction on an already-ready draft — should update date and stay ready.
    func testDateCorrectionOnReadyDraft() {
        let ready = service.handleUserMessage("gym $80 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertTrue(ready.pendingDraft?.readyForConfirmation == true)

        let corrected = service.handleUserMessage("actually the 10th", existingDraft: ready.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertNotNil(corrected.pendingDraft?.nextDueDate)
        XCTAssertTrue(corrected.pendingDraft?.readyForConfirmation == true)
        // Amount and title must survive a date-only correction
        XCTAssertEqual(corrected.pendingDraft?.amount?.amount, Decimal(string: "80"))
        XCTAssertTrue(corrected.pendingDraft?.title?.lowercased().contains("gym") == true)
    }

    // Cadence correction on an already-ready draft — should update cadence and stay ready.
    func testCadenceCorrectionOnReadyDraft() {
        let ready = service.handleUserMessage("gym $80 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertTrue(ready.pendingDraft?.readyForConfirmation == true)

        let corrected = service.handleUserMessage("actually weekly", existingDraft: ready.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertEqual(corrected.pendingDraft?.cadence, .weekly)
        XCTAssertTrue(corrected.pendingDraft?.readyForConfirmation == true)
        XCTAssertEqual(corrected.pendingDraft?.amount?.amount, Decimal(string: "80"))
    }

    // Noise reply ("ok", "looks good") on a ready draft must NOT overwrite the established title.
    // Bug before fix: inferTitle("ok") → "Ok" → merge overwrote the existing title.
    func testNoiseReplyOnReadyDraftDoesNotOverwriteTitle() {
        let ready = service.handleUserMessage("gym $80 monthly on the 5th", existingDraft: nil, profile: usdProfile, memories: [])
        let originalTitle = ready.pendingDraft?.title
        XCTAssertNotNil(originalTitle)

        let after = service.handleUserMessage("ok", existingDraft: ready.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertEqual(after.pendingDraft?.title, originalTitle,
                       "Noise reply 'ok' must not replace the existing title")
    }

    func testLooksGoodReplyOnReadyDraftDoesNotOverwriteTitle() {
        let ready = service.handleUserMessage("Netflix $15.99 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])
        let originalTitle = ready.pendingDraft?.title

        let after = service.handleUserMessage("looks good", existingDraft: ready.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertEqual(after.pendingDraft?.title, originalTitle,
                       "Noise reply 'looks good' must not replace the existing title")
        // All other fields must be preserved
        XCTAssertEqual(after.pendingDraft?.amount?.amount, Decimal(string: "15.99"))
        XCTAssertEqual(after.pendingDraft?.cadence, .monthly)
        XCTAssertTrue(after.pendingDraft?.readyForConfirmation == true)
    }

    // Catalog name typed again on a ready draft — catalog title overrides (intentional correction).
    func testCatalogMatchOnReadyDraftOverridesTitle() {
        let ready = service.handleUserMessage("some subscription $9.99 monthly on the 1st", existingDraft: nil, profile: usdProfile, memories: [])
        XCTAssertTrue(ready.pendingDraft?.readyForConfirmation == true)

        // User clarifies it's actually Netflix — catalog should update the title
        let after = service.handleUserMessage("Netflix", existingDraft: ready.pendingDraft, profile: usdProfile, memories: [])
        XCTAssertTrue(after.pendingDraft?.title?.lowercased().contains("netflix") == true,
                      "Explicit catalog match should update the title even on a ready draft")
    }
}
