import Foundation

struct AssistantTurn {
    var assistantMessage: ChatMessage
    var pendingDraft: ExtractionDraft?
}

struct FinanceAssistantService {
    let catalogService = CatalogService()

    func handleUserMessage(
        _ text: String,
        existingDraft: ExtractionDraft?,
        profile: UserProfile,
        memories: [FinanceMemory]
    ) -> AssistantTurn {
        let mergedDraft = merge(parse(text: text, profile: profile, existingTitle: existingDraft?.title), into: existingDraft, sourceText: text, profile: profile, memories: memories)
        let missingFields = validate(mergedDraft)
        var finalDraft = mergedDraft
        finalDraft.missingFields = missingFields
        finalDraft.readyForConfirmation = missingFields.isEmpty

        let assistantBody: String
        if let firstMissingField = missingFields.first {
            assistantBody = firstMissingField.question
        } else {
            let title = finalDraft.title ?? "this recurring item"
            let amount = finalDraft.amount?.formatted(localeIdentifier: profile.localeIdentifier) ?? ""
            let cadence = finalDraft.cadence?.displayTitle.lowercased() ?? "recurring"
            let dueDate = finalDraft.nextDueDate?.formattedMonthDay() ?? ""
            let typeTitle = finalDraft.itemType?.displayTitle.lowercased() ?? "entry"
            assistantBody = "I captured \(title) as a \(cadence) \(typeTitle) for \(amount), next due \(dueDate). Confirm to save it or edit any field first."
        }

        return AssistantTurn(
            assistantMessage: ChatMessage(id: UUID(), role: .assistant, body: assistantBody, createdAt: .now),
            pendingDraft: finalDraft
        )
    }

    private func parse(text: String, profile: UserProfile, existingTitle: String? = nil) -> ExtractionDraft {
        var draft = ExtractionDraft.empty()
        draft.sourceText = text
        let lowercase = text.lowercased()

        if let match = catalogService.bestMatch(in: text) {
            draft.title = match.title
            draft.merchant = match.title
            draft.category = match.category
            draft.symbolName = match.symbolName
            draft.cadence = match.cadence
            if let defaultPrice = match.defaultPricing[profile.defaultCurrencyCode] ?? match.defaultPricing["USD"] {
                draft.amount = MoneyAmount(amount: defaultPrice, currencyCode: profile.defaultCurrencyCode)
            }
            if match.category == "Income" {
                draft.itemType = .income
            } else {
                draft.itemType = .expense
            }
        }

        if let parsedAmount = parseAmount(in: text, defaultCurrencyCode: draft.amount?.currencyCode ?? profile.defaultCurrencyCode) {
            draft.amount = parsedAmount
        }

        if let cadence = parseCadence(in: lowercase) {
            draft.cadence = cadence
        }

        if let dueDate = parseDate(in: text, cadence: draft.cadence) {
            draft.nextDueDate = dueDate
        }

        if let itemType = parseItemType(in: lowercase) {
            draft.itemType = itemType
        }
        // Note: .expense default is NOT set here — it is applied only for brand-new items
        // in merge(), so that multi-turn replies don't overwrite an existing income type.

        // Only infer a title heuristically when no title exists yet (first turn or draft has no title).
        // Skipping when existingTitle is set prevents noise replies like "ok" / "28" from
        // overwriting an already-established title on subsequent turns.
        if draft.title == nil, existingTitle == nil {
            draft.title = inferTitle(from: text)
        }

        if draft.merchant == nil {
            draft.merchant = draft.title
        }

        if draft.category == nil {
            draft.category = draft.itemType == .income ? "Income" : "Subscriptions"
        }

        if draft.symbolName == nil {
            draft.symbolName = draft.itemType == .income ? "banknote" : "creditcard"
        }

        if draft.paymentMethodLabel == nil, !profile.defaultPaymentMethodLabel.isEmpty {
            draft.paymentMethodLabel = profile.defaultPaymentMethodLabel
        }

        return draft
    }

    private func merge(
        _ update: ExtractionDraft,
        into existingDraft: ExtractionDraft?,
        sourceText: String,
        profile: UserProfile,
        memories: [FinanceMemory]
    ) -> ExtractionDraft {
        guard var merged = existingDraft else {
            var fresh = update
            // Apply .expense default only for brand-new items (no prior draft).
            if fresh.itemType == nil { fresh.itemType = .expense }
            fresh.homeAmount = update.amount.map { MoneyAmount(amount: $0.amount, currencyCode: profile.defaultCurrencyCode) }
            return fresh
        }

        merged.sourceText += merged.sourceText.isEmpty ? sourceText : " \(sourceText)"
        merged.title = update.title ?? merged.title
        merged.merchant = update.merchant ?? merged.merchant
        merged.category = update.category ?? merged.category
        merged.symbolName = update.symbolName ?? merged.symbolName
        merged.amount = update.amount ?? merged.amount
        merged.cadence = update.cadence ?? merged.cadence
        merged.nextDueDate = update.nextDueDate ?? merged.nextDueDate
        merged.itemType = update.itemType ?? merged.itemType
        if let paymentMethodLabel = update.paymentMethodLabel, !paymentMethodLabel.isEmpty {
            merged.paymentMethodLabel = paymentMethodLabel
        }
        if merged.amount == nil,
           let knownCurrency = memories.first(where: { $0.key == "defaultCurrency" })?.value {
            merged.amount = MoneyAmount(amount: .zero, currencyCode: knownCurrency)
        }
        if merged.paymentMethodLabel == nil, !profile.defaultPaymentMethodLabel.isEmpty {
            merged.paymentMethodLabel = profile.defaultPaymentMethodLabel
        }
        return merged
    }

    private func validate(_ draft: ExtractionDraft) -> [DraftField] {
        var missingFields: [DraftField] = []
        if draft.title?.isEmpty ?? true {
            missingFields.append(.title)
        }
        if draft.amount == nil || draft.amount?.amount == .zero {
            missingFields.append(.amount)
        }
        if draft.cadence == nil {
            missingFields.append(.cadence)
        }
        if draft.nextDueDate == nil {
            missingFields.append(.nextDueDate)
        }
        if draft.itemType == nil {
            missingFields.append(.itemType)
        }
        return missingFields
    }

    private func parseCadence(in text: String) -> RecurrenceCadence? {
        if text.contains("daily") || text.contains("every day") {
            return .daily
        }
        if text.contains("weekly") || text.contains("every week") {
            return .weekly
        }
        if text.contains("yearly") || text.contains("annual") || text.contains("annually") {
            return .yearly
        }
        // \bmonths?\b covers installment phrasing: "24 month plan", "12-month installment", "a month"
        // Word-boundary prevents matching typos like "monthy".
        if text.contains("monthly") || text.contains("every month") || text.contains("/mo")
            || text.range(of: #"\bmonths?\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return .monthly
        }
        return nil
    }

    private func parseItemType(in text: String) -> RecurringItemType? {
        let incomeHints = ["salary", "income", "paycheck", "bonus", "freelance"]
        if incomeHints.contains(where: text.contains) {
            return .income
        }

        let expenseHints = ["subscription", "bill", "cost", "expense", "pay", "renewal"]
        if expenseHints.contains(where: text.contains) {
            return .expense
        }

        return nil
    }

    private func parseAmount(in text: String, defaultCurrencyCode: String) -> MoneyAmount? {
        // (?:\d*) after the capture group consumes any extra decimal digits (e.g. "$15.999" → captures
        // "15.99" then consumes the trailing "9"), preventing backtracking to a shorter match.
        // (?!\d) then ensures we haven't left a digit unconsumed (guards against matching "2" from "28").
        let pattern = #"(?:(USD|SGD|EUR|GBP|JPY)\s*)?([$€£¥])?\s?(\d+(?:\.\d{1,2})?)(?:\d*)(?!\d)(?!\s*(?:st|nd|rd|th|th\b))"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        // Prefer currency-prefixed amounts over bare numbers so that
        // "iphone 24 month installment plan $150" picks $150 not 24.
        // Rank: explicit code (USD/SGD/…) = 3, symbol ($€£¥) = 2, bare = 1.
        var bestAmount: MoneyAmount?
        var bestRank = 0

        for match in matches {
            let codeRange = Range(match.range(at: 1), in: text)
            let symbolRange = Range(match.range(at: 2), in: text)
            let valueRange = Range(match.range(at: 3), in: text)

            guard let vRange = valueRange, let decimal = Decimal(string: String(text[vRange])) else { continue }

            // Reject numbers ≤ 31 that look like date responses:
            // - "on the 15" / "the 15"
            // - bare number alone (e.g. user replying "28" to a date prompt)
            if codeRange == nil && symbolRange == nil && decimal <= 31 {
                let vString = String(text[vRange])
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if text.contains("the \(vString)") || text.contains("on \(vString)")
                    || trimmed == vString {
                    continue
                }
            }

            let rank: Int
            if codeRange != nil { rank = 3 }
            else if symbolRange != nil { rank = 2 }
            else { rank = 1 }

            // Only promote; never replace a higher-ranked match with a lower one.
            guard rank > bestRank else { continue }

            let currencyCode: String
            if let cRange = codeRange {
                currencyCode = String(text[cRange]).uppercased()
            } else if let sRange = symbolRange {
                switch String(text[sRange]) {
                case "$": currencyCode = defaultCurrencyCode
                case "€": currencyCode = "EUR"
                case "£": currencyCode = "GBP"
                case "¥": currencyCode = "JPY"
                default: currencyCode = defaultCurrencyCode
                }
            } else {
                currencyCode = defaultCurrencyCode
            }

            bestRank = rank
            bestAmount = MoneyAmount(amount: decimal, currencyCode: currencyCode)
        }
        return bestAmount
    }

    private func parseDate(in text: String, cadence: RecurrenceCadence?) -> Date? {
        // 1. Bare integer 1–31: user is replying with just a day number (e.g. "28")
        //    Check this first so it takes priority over NSDataDetector.
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let dayNumber = Int(trimmed), dayNumber >= 1, dayNumber <= 31 {
            return inferredRecurringDate(day: dayNumber, cadence: cadence ?? .monthly)
        }

        // 2. NSDataDetector for natural-language dates ("April 13", "next Monday", etc.)
        //    Guards against two phantom-date patterns:
        //    a) Bare weekday abbreviation ("mon"/"tue") — no digit in matched text → skip.
        //    b) Time-like number + weekday abbreviation ("500 a mon" → NSDataDetector reads
        //       "500" as 5:00 and "mon" as Monday). Detect this by checking whether the
        //       matched text contains a weekday abbreviation with no month name or ordinal.
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = detector.firstMatch(in: text, range: range),
               let date = match.date,
               let matchedRange = Range(match.range, in: text) {
                let matchedLower = String(text[matchedRange]).lowercased()
                let hasDigit = matchedLower.contains(where: \.isNumber)
                let tokens = matchedLower
                    .components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                let weekdays: Set<String> = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
                let months: Set<String> = ["jan", "feb", "mar", "apr", "may", "jun",
                                           "jul", "aug", "sep", "oct", "nov", "dec"]
                let hasWeekday = tokens.contains { weekdays.contains($0) }
                let hasMonth = tokens.contains { months.contains(String($0.prefix(3))) }
                let hasOrdinal = matchedLower.range(of: #"\d{1,2}(?:st|nd|rd|th)"#,
                                                    options: .regularExpression) != nil
                // Accept only when: digit present AND not a weekday-only context
                if hasDigit && (hasMonth || hasOrdinal || !hasWeekday) {
                    return Calendar.current.startOfDay(for: date)
                }
            }
        }

        let lowercase = text.lowercased()
        if lowercase.contains("today") {
            return Calendar.current.startOfDay(for: .now)
        }
        if lowercase.contains("tomorrow"), let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) {
            return Calendar.current.startOfDay(for: tomorrow)
        }

        // 3. Ordinal pattern: "28th", "1st", "3rd"
        let ordinalPattern = #"(\d{1,2})(?:st|nd|rd|th)"#
        if let regex = try? NSRegularExpression(pattern: ordinalPattern),
           let match = regex.firstMatch(in: lowercase, range: NSRange(lowercase.startIndex..., in: lowercase)),
           let range = Range(match.range(at: 1), in: lowercase),
           let day = Int(lowercase[range]) {
            return inferredRecurringDate(day: day, cadence: cadence ?? .monthly)
        }

        return nil
    }

    private func inferredRecurringDate(day: Int, cadence: RecurrenceCadence) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        switch cadence {
        case .daily:
            return today
        case .weekly:
            return today
        case .monthly, .yearly:
            var components = calendar.dateComponents([.year, .month], from: today)
            components.day = day
            let thisMonth = calendar.date(from: components)
            if let thisMonth, thisMonth >= today {
                return thisMonth
            }
            return calendar.date(byAdding: .month, value: 1, to: thisMonth ?? today)
        }
    }

    private func inferTitle(from text: String) -> String? {
        let quotedPattern = #""([^"]+)""#
        if let regex = try? NSRegularExpression(pattern: quotedPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }

        let cleaned = text
            .replacingOccurrences(of: #"[$€£¥]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\b(daily|weekly|monthly|yearly|income|expense|subscription|bill|cost|salary|on|the|every)\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            return nil
        }

        let result = cleaned.split(separator: " ").prefix(3).joined(separator: " ").capitalized
        // Don't use a purely numeric string as a title — it's almost certainly a date response
        guard !result.allSatisfy({ $0.isNumber || $0.isWhitespace }) else {
            return nil
        }
        return result
    }
}

