import Foundation

enum AppTab: String, CaseIterable, Identifiable, Codable {
    case chat = "Chat"
    case dashboard = "Dashboard"

    var id: String { rawValue }
}

enum RecurringItemType: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .expense: "Expense"
        case .income: "Income"
        }
    }
}

enum RecurrenceCadence: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var displayTitle: String {
        rawValue.capitalized
    }
}

enum RecurringItemStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case paused
    case archived

    var id: String { rawValue }
}

enum ItemSource: String, Codable {
    case chat
    case manual
}

enum NotificationPermissionStatus: String, Codable {
    case unknown
    case denied
    case authorized
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

enum SubscriptionPlan: String, Codable, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}

struct MoneyAmount: Codable, Hashable {
    var amount: Decimal
    var currencyCode: String

    static func zero(currencyCode: String) -> MoneyAmount {
        MoneyAmount(amount: .zero, currencyCode: currencyCode)
    }
}

struct ReminderSettings: Codable, Hashable {
    var isEnabled: Bool
    var daysBefore: Int

    static let disabled = ReminderSettings(isEnabled: false, daysBefore: 3)
}

struct UserProfile: Hashable {
    var id: UUID
    var displayName: String
    var email: String?
    var appleUserID: String?
    var localeIdentifier: String
    var defaultCurrencyCode: String
    var defaultPaymentMethodLabel: String
    var aggregateLearningConsent: Bool
    var notificationPermissionStatus: NotificationPermissionStatus
    // User-defined payment methods appended to the built-in list
    var customPaymentMethods: [String]

    static var empty: UserProfile {
        let locale = Locale.current
        let currency = locale.currency?.identifier ?? "USD"
        return UserProfile(
            id: UUID(),
            displayName: "",
            email: nil,
            localeIdentifier: locale.identifier.isEmpty ? "en_US" : locale.identifier,
            defaultCurrencyCode: currency,
            defaultPaymentMethodLabel: "",
            aggregateLearningConsent: false,
            notificationPermissionStatus: .unknown,
            customPaymentMethods: []
        )
    }
}

extension UserProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case id, displayName, email, appleUserID, localeIdentifier
        case defaultCurrencyCode, defaultPaymentMethodLabel
        case aggregateLearningConsent, notificationPermissionStatus
        case customPaymentMethods
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        displayName = try c.decode(String.self, forKey: .displayName)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        appleUserID = try c.decodeIfPresent(String.self, forKey: .appleUserID)
        localeIdentifier = try c.decode(String.self, forKey: .localeIdentifier)
        defaultCurrencyCode = try c.decode(String.self, forKey: .defaultCurrencyCode)
        defaultPaymentMethodLabel = try c.decode(String.self, forKey: .defaultPaymentMethodLabel)
        aggregateLearningConsent = try c.decode(Bool.self, forKey: .aggregateLearningConsent)
        notificationPermissionStatus = try c.decode(NotificationPermissionStatus.self, forKey: .notificationPermissionStatus)
        // Graceful migration: existing sessions without this key default to empty
        customPaymentMethods = try c.decodeIfPresent([String].self, forKey: .customPaymentMethods) ?? []
    }
}

struct RecurringItem: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var merchant: String
    var category: String
    var symbolName: String
    var originalAmount: MoneyAmount
    var homeAmount: MoneyAmount
    var cadence: RecurrenceCadence
    var nextDueDate: Date
    var itemType: RecurringItemType
    var paymentMethodLabel: String?
    var reminder: ReminderSettings
    var source: ItemSource
    var status: RecurringItemStatus
    var createdAt: Date
    var updatedAt: Date
}

struct OccurrenceProjection: Identifiable, Hashable {
    var id: String
    var itemID: UUID
    var title: String
    var symbolName: String
    var itemType: RecurringItemType
    var originalAmount: MoneyAmount
    var homeAmount: MoneyAmount
    var date: Date
}

struct ChatMessage: Codable, Identifiable, Hashable {
    var id: UUID
    var role: MessageRole
    var body: String
    var createdAt: Date
}

enum DraftField: String, Codable, CaseIterable, Identifiable {
    case title
    case amount
    case cadence
    case nextDueDate
    case itemType

    var id: String { rawValue }

    var question: String {
        switch self {
        case .title:
            "What should I call this recurring item?"
        case .amount:
            "What amount should I save for it?"
        case .cadence:
            "How often does it repeat: daily, weekly, monthly, or yearly?"
        case .nextDueDate:
            "When is the next date it will hit?"
        case .itemType:
            "Is this an income or an expense?"
        }
    }
}

struct ExtractionDraft: Codable, Identifiable, Hashable {
    var id: UUID
    var sourceText: String
    var title: String?
    var merchant: String?
    var category: String?
    var symbolName: String?
    var amount: MoneyAmount?
    var homeAmount: MoneyAmount?
    var cadence: RecurrenceCadence?
    var nextDueDate: Date?
    var itemType: RecurringItemType?
    var paymentMethodLabel: String?
    var source: ItemSource
    var missingFields: [DraftField]
    var readyForConfirmation: Bool

    static func empty(source: ItemSource = .chat) -> ExtractionDraft {
        ExtractionDraft(
            id: UUID(),
            sourceText: "",
            title: nil,
            merchant: nil,
            category: nil,
            symbolName: nil,
            amount: nil,
            homeAmount: nil,
            cadence: nil,
            nextDueDate: nil,
            itemType: nil,
            paymentMethodLabel: nil,
            source: source,
            missingFields: DraftField.allCases,
            readyForConfirmation: false
        )
    }
}

struct ChatThread: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var messages: [ChatMessage]
    var pendingDraft: ExtractionDraft?
}

struct FinanceMemory: Codable, Identifiable, Hashable {
    var id: UUID
    var key: String
    var value: String
    var lastUpdatedAt: Date
}

struct CatalogEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var aliases: [String]
    var category: String
    var symbolName: String
    var defaultPricing: [String: Decimal]
    var cadence: RecurrenceCadence
    var popularity: Int
}

struct AggregateStats: Codable, Hashable {
    var merchantPopularity: [String: Int]
    var merchantCategoryDefaults: [String: String]
}

struct SubscriptionOffering: Codable, Identifiable, Hashable {
    var id: UUID
    var plan: SubscriptionPlan
    var title: String
    var subtitle: String
    var priceLabel: String
    var hasFreeTrial: Bool
}

struct EntitlementSnapshot: Codable, Hashable {
    var trialStartedAt: Date?
    var trialEndsAt: Date?
    var scheduledPlan: SubscriptionPlan?
    var activePlan: SubscriptionPlan?

    func hasPremiumAccess(now: Date = .now) -> Bool {
        if activePlan != nil {
            return true
        }
        if let trialEndsAt {
            return now <= trialEndsAt
        }
        return false
    }

    func isReadOnly(now: Date = .now) -> Bool {
        !hasPremiumAccess(now: now)
    }
}

struct InsightCard: Identifiable, Hashable {
    enum Tone: String, Hashable {
        case neutral
        case positive
        case caution
    }

    var id: UUID
    var title: String
    var message: String
    var tone: Tone
}

struct PersistedSession: Codable {
    var profile: UserProfile
    var recurringItems: [RecurringItem]
    var chatThreads: [ChatThread]
    var memories: [FinanceMemory]
    var aggregateStats: AggregateStats
    var entitlement: EntitlementSnapshot
    var activeThreadID: UUID?
    var hasCompletedOnboarding: Bool

    static let empty = PersistedSession(
        profile: .empty,
        recurringItems: [],
        chatThreads: [],
        memories: [],
        aggregateStats: AggregateStats(
            merchantPopularity: [
                "ChatGPT Plus": 93,
                "Netflix": 88,
                "Spotify Premium": 84,
                "YouTube Premium": 72,
                "Apple One": 64
            ],
            merchantCategoryDefaults: [
                "ChatGPT Plus": "Productivity",
                "Netflix": "Entertainment",
                "Spotify Premium": "Entertainment",
                "YouTube Premium": "Entertainment",
                "Apple One": "Utilities"
            ]
        ),
        entitlement: EntitlementSnapshot(trialStartedAt: nil, trialEndsAt: nil, scheduledPlan: nil, activePlan: nil),
        activeThreadID: nil,
        hasCompletedOnboarding: false
    )
}

struct DashboardSummary: Hashable {
    var incomeTotal: MoneyAmount
    var expenseTotal: MoneyAmount
    var projectedNet: MoneyAmount
}

enum DashboardFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case expenses = "Expenses"
    case income = "Income"
    case upcoming = "Upcoming"
    case overdue = "Overdue"

    var id: String { rawValue }
}

struct RecurringItemFormState: Hashable {
    var title: String
    var merchant: String
    var category: String
    var symbolName: String
    var amountText: String
    var currencyCode: String
    var cadence: RecurrenceCadence
    var nextDueDate: Date
    var itemType: RecurringItemType
    var paymentMethodLabel: String
    var remindersEnabled: Bool
    var reminderDaysBefore: Int

    static func blank(defaultCurrencyCode: String, paymentMethod: String) -> RecurringItemFormState {
        RecurringItemFormState(
            title: "",
            merchant: "",
            category: "",
            symbolName: "creditcard",
            amountText: "",
            currencyCode: defaultCurrencyCode,
            cadence: .monthly,
            nextDueDate: .now,
            itemType: .expense,
            paymentMethodLabel: paymentMethod,
            remindersEnabled: false,
            reminderDaysBefore: 3
        )
    }
}
