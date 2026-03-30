import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var session: PersistedSession
    var selectedTab: AppTab = .chat
    var isSidebarPresented = false
    var selectedMonth: Date = .now
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    var dashboardFilter: DashboardFilter = .all
    var composerText = ""
    var editorDraft: RecurringItemFormState?
    var editingItemID: UUID?
    var statusBanner: String?

    let persistence: SessionPersisting
    let subscriptionService: SubscriptionProviding
    let syncService: CloudSyncing
    let accountService: AccountProviding
    let assistantService = FinanceAssistantService()
    let catalogService = CatalogService()
    let conversionService = CurrencyConversionService()
    let projectionEngine = ProjectionEngine()
    let insightsEngine = InsightsEngine()
    let reminderScheduler: ReminderScheduling

    init(
        persistence: SessionPersisting = LocalJSONPersistence(),
        subscriptionService: SubscriptionProviding = MockSubscriptionService(),
        syncService: CloudSyncing = PlaceholderCloudSyncService(),
        accountService: AccountProviding = LocalAccountService(),
        reminderScheduler: ReminderScheduling = LocalReminderScheduler()
    ) {
        self.persistence = persistence
        self.subscriptionService = subscriptionService
        self.syncService = syncService
        self.accountService = accountService
        self.reminderScheduler = reminderScheduler

        if let loaded = try? persistence.load() {
            session = loaded
        } else {
            session = .empty
        }

        session.profile = accountService.bootstrapProfile(existing: session.profile)
        if session.chatThreads.isEmpty {
            let thread = Self.makeWelcomeThread()
            session.chatThreads = [thread]
            session.activeThreadID = thread.id
        }
        saveSession()
    }

    var activeThread: ChatThread {
        get {
            if let activeThreadID = session.activeThreadID,
               let thread = session.chatThreads.first(where: { $0.id == activeThreadID }) {
                return thread
            }
            let thread = session.chatThreads.first ?? Self.makeWelcomeThread()
            if session.chatThreads.isEmpty {
                session.chatThreads = [thread]
                session.activeThreadID = thread.id
            }
            return thread
        }
        set {
            if let index = session.chatThreads.firstIndex(where: { $0.id == newValue.id }) {
                session.chatThreads[index] = newValue
            } else {
                session.chatThreads.insert(newValue, at: 0)
            }
            session.activeThreadID = newValue.id
            session.chatThreads.sort { $0.updatedAt > $1.updatedAt }
        }
    }

    var isReadOnly: Bool {
        session.hasCompletedOnboarding && session.entitlement.isReadOnly()
    }

    var dashboardSummary: DashboardSummary {
        projectionEngine.summary(for: session.recurringItems, in: session.profile.defaultCurrencyCode, monthAnchor: selectedMonth)
    }

    var occurrenceGroups: [Date: [OccurrenceProjection]] {
        projectionEngine.groupedOccurrences(for: session.recurringItems, in: selectedMonth)
    }

    var filteredItems: [RecurringItem] {
        let startOfSelectedDate = Calendar.current.startOfDay(for: selectedDate)
        let now = Calendar.current.startOfDay(for: .now)

        return session.recurringItems
            .filter { item in
                switch dashboardFilter {
                case .all:
                    true
                case .expenses:
                    item.itemType == .expense
                case .income:
                    item.itemType == .income
                case .upcoming:
                    item.nextDueDate >= now
                case .overdue:
                    item.nextDueDate < now
                }
            }
            .filter { item in
                let projections = projectionEngine.occurrences(for: item, in: selectedMonth)
                return projections.contains { Calendar.current.isDate($0.date, inSameDayAs: startOfSelectedDate) }
                    || dashboardFilter != .all
            }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }

    var insights: [InsightCard] {
        insightsEngine.generateInsights(
            items: session.recurringItems,
            monthAnchor: selectedMonth,
            homeCurrencyCode: session.profile.defaultCurrencyCode,
            catalogService: catalogService,
            aggregateStats: session.aggregateStats,
            allowAggregateLearning: session.profile.aggregateLearningConsent
        )
    }

    func nextMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }

    func previousMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }

    func selectThread(_ thread: ChatThread) {
        session.activeThreadID = thread.id
        isSidebarPresented = false
        saveSession()
    }

    func createNewThread() {
        let thread = Self.makeWelcomeThread()
        activeThread = thread
        saveSession()
    }

    func deleteThread(_ thread: ChatThread) {
        session.chatThreads.removeAll { $0.id == thread.id }
        if session.chatThreads.isEmpty {
            let replacement = Self.makeWelcomeThread()
            session.chatThreads = [replacement]
            session.activeThreadID = replacement.id
        } else if session.activeThreadID == thread.id {
            session.activeThreadID = session.chatThreads.first?.id
        }
        saveSession()
    }

    func submitComposer() {
        let message = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        composerText = ""
        submitChatMessage(message)
    }

    func submitChatMessage(_ text: String) {
        var thread = activeThread
        let userMessage = ChatMessage(id: UUID(), role: .user, body: text, createdAt: .now)
        thread.messages.append(userMessage)
        let turn = assistantService.handleUserMessage(text, existingDraft: thread.pendingDraft, profile: session.profile, memories: session.memories)
        thread.messages.append(turn.assistantMessage)
        thread.pendingDraft = turn.pendingDraft
        if thread.title == "New chat" {
            thread.title = (turn.pendingDraft?.title?.isEmpty == false ? turn.pendingDraft?.title : text.split(separator: " ").prefix(3).joined(separator: " ")) ?? "New chat"
        }
        thread.updatedAt = .now
        activeThread = thread
        saveSession()
    }

    func confirmPendingDraft() {
        guard let draft = activeThread.pendingDraft, draft.readyForConfirmation, !isReadOnly else {
            return
        }
        guard let item = recurringItem(from: draft, source: .chat) else {
            return
        }
        upsert(item: item)

        var thread = activeThread
        thread.pendingDraft = nil
        thread.messages.append(
            ChatMessage(
                id: UUID(),
                role: .assistant,
                body: "Saved \(item.title) to your dashboard. You can edit it anytime from the calendar or items list.",
                createdAt: .now
            )
        )
        thread.updatedAt = .now
        activeThread = thread
        updateMemories(with: item)
        Task {
            await refreshReminders()
        }
        saveSession()
    }

    func editPendingDraft() {
        guard let draft = activeThread.pendingDraft else { return }
        editorDraft = formState(from: draft)
        editingItemID = nil
    }

    func openEditor(for item: RecurringItem?) {
        if let item {
            editorDraft = formState(from: item)
            editingItemID = item.id
        } else {
            editorDraft = .blank(defaultCurrencyCode: session.profile.defaultCurrencyCode, paymentMethod: session.profile.defaultPaymentMethodLabel)
            editingItemID = nil
        }
    }

    func closeEditor() {
        editorDraft = nil
        editingItemID = nil
    }

    func saveEditor() {
        guard let editorDraft, !isReadOnly else { return }
        guard let item = recurringItem(from: editorDraft, source: editingItemID == nil ? .manual : itemSource(for: editingItemID)) else {
            statusBanner = "Please complete the required fields before saving."
            return
        }
        upsert(item: item)
        updateMemories(with: item)
        closeEditor()
        Task {
            await refreshReminders()
        }
        saveSession()
    }

    func pauseOrResume(_ item: RecurringItem) {
        guard !isReadOnly else { return }
        var updated = item
        updated.status = item.status == .paused ? .active : .paused
        updated.updatedAt = .now
        upsert(item: updated)
        saveSession()
    }

    func deleteItem(_ item: RecurringItem) {
        guard !isReadOnly else { return }
        session.recurringItems.removeAll { $0.id == item.id }
        saveSession()
    }

    func completeOnboarding(profile: UserProfile, firstItem: RecurringItem?, startTrialPlan: SubscriptionPlan?) {
        session.profile = profile
        if let firstItem {
            upsert(item: firstItem)
            updateMemories(with: firstItem)
        }
        session.hasCompletedOnboarding = true
        if session.chatThreads.isEmpty {
            let thread = Self.makeWelcomeThread()
            session.chatThreads = [thread]
            session.activeThreadID = thread.id
        }
        selectedDate = Calendar.current.startOfDay(for: .now)
        saveSession()
        if let startTrialPlan {
            Task {
                do {
                    session.entitlement = try await subscriptionService.beginTrial(for: startTrialPlan, from: session.entitlement)
                    saveSession()
                } catch {
                    statusBanner = "Unable to start trial. Please try again."
                }
            }
        }
    }

    func purchase(plan: SubscriptionPlan) {
        Task {
            do {
                session.entitlement = try await subscriptionService.purchase(plan: plan, from: session.entitlement)
                saveSession()
            } catch {
                statusBanner = "Purchase failed. Please try again."
            }
        }
    }

    func restorePurchases() {
        Task {
            do {
                session.entitlement = try await subscriptionService.restore(snapshot: session.entitlement)
                saveSession()
            } catch {
                statusBanner = "Restore failed. Please try again."
            }
        }
    }

    func dismissBanner() {
        statusBanner = nil
    }

    private func upsert(item: RecurringItem) {
        if let index = session.recurringItems.firstIndex(where: { $0.id == item.id }) {
            session.recurringItems[index] = item
        } else {
            session.recurringItems.append(item)
        }
        session.recurringItems.sort { $0.nextDueDate < $1.nextDueDate }
    }

    private func recurringItem(from draft: ExtractionDraft, source: ItemSource) -> RecurringItem? {
        guard
            let title = draft.title, !title.isEmpty,
            let merchant = draft.merchant,
            let category = draft.category,
            let symbolName = draft.symbolName,
            let originalAmount = draft.amount,
            let cadence = draft.cadence,
            let nextDueDate = draft.nextDueDate,
            let itemType = draft.itemType
        else {
            return nil
        }

        let homeAmount = conversionService.convert(originalAmount, to: session.profile.defaultCurrencyCode)
        return RecurringItem(
            id: UUID(),
            title: title,
            merchant: merchant,
            category: category,
            symbolName: symbolName,
            originalAmount: originalAmount,
            homeAmount: homeAmount,
            cadence: cadence,
            nextDueDate: nextDueDate,
            itemType: itemType,
            paymentMethodLabel: draft.paymentMethodLabel,
            reminder: ReminderSettings.disabled,
            source: source,
            status: .active,
            createdAt: .now,
            updatedAt: .now
        )
    }

    private func recurringItem(from form: RecurringItemFormState, source: ItemSource) -> RecurringItem? {
        guard
            let amount = Decimal(string: form.amountText.replacingOccurrences(of: ",", with: ".")),
            !form.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !form.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        let originalAmount = MoneyAmount(amount: amount, currencyCode: form.currencyCode)
        let homeAmount = conversionService.convert(originalAmount, to: session.profile.defaultCurrencyCode)
        let existingCreatedAt = session.recurringItems.first(where: { $0.id == editingItemID })?.createdAt ?? .now

        return RecurringItem(
            id: editingItemID ?? UUID(),
            title: form.title,
            merchant: form.merchant.isEmpty ? form.title : form.merchant,
            category: form.category,
            symbolName: form.symbolName,
            originalAmount: originalAmount,
            homeAmount: homeAmount,
            cadence: form.cadence,
            nextDueDate: form.nextDueDate,
            itemType: form.itemType,
            paymentMethodLabel: form.paymentMethodLabel.isEmpty ? nil : form.paymentMethodLabel,
            reminder: ReminderSettings(isEnabled: form.remindersEnabled, daysBefore: form.reminderDaysBefore),
            source: source,
            status: session.recurringItems.first(where: { $0.id == editingItemID })?.status ?? .active,
            createdAt: existingCreatedAt,
            updatedAt: .now
        )
    }

    private func formState(from draft: ExtractionDraft) -> RecurringItemFormState {
        RecurringItemFormState(
            title: draft.title ?? "",
            merchant: draft.merchant ?? draft.title ?? "",
            category: draft.category ?? "",
            symbolName: draft.symbolName ?? "creditcard",
            amountText: draft.amount?.amount.description ?? "",
            currencyCode: draft.amount?.currencyCode ?? session.profile.defaultCurrencyCode,
            cadence: draft.cadence ?? .monthly,
            nextDueDate: draft.nextDueDate ?? .now,
            itemType: draft.itemType ?? .expense,
            paymentMethodLabel: draft.paymentMethodLabel ?? session.profile.defaultPaymentMethodLabel,
            remindersEnabled: false,
            reminderDaysBefore: 3
        )
    }

    private func formState(from item: RecurringItem) -> RecurringItemFormState {
        RecurringItemFormState(
            title: item.title,
            merchant: item.merchant,
            category: item.category,
            symbolName: item.symbolName,
            amountText: item.originalAmount.amount.description,
            currencyCode: item.originalAmount.currencyCode,
            cadence: item.cadence,
            nextDueDate: item.nextDueDate,
            itemType: item.itemType,
            paymentMethodLabel: item.paymentMethodLabel ?? "",
            remindersEnabled: item.reminder.isEnabled,
            reminderDaysBefore: item.reminder.daysBefore
        )
    }

    private func updateMemories(with item: RecurringItem) {
        let newMemories: [FinanceMemory] = [
            FinanceMemory(id: UUID(), key: "defaultCurrency", value: session.profile.defaultCurrencyCode, lastUpdatedAt: .now),
            FinanceMemory(id: UUID(), key: "lastMerchant", value: item.merchant, lastUpdatedAt: .now),
            FinanceMemory(id: UUID(), key: "lastCadence", value: item.cadence.rawValue, lastUpdatedAt: .now)
        ]
        for memory in newMemories {
            if let index = session.memories.firstIndex(where: { $0.key == memory.key }) {
                session.memories[index] = memory
            } else {
                session.memories.append(memory)
            }
        }
    }

    private func itemSource(for itemID: UUID?) -> ItemSource {
        session.recurringItems.first(where: { $0.id == itemID })?.source ?? .manual
    }

    private func saveSession() {
        do {
            try persistence.save(session)
        } catch {
            statusBanner = "Unable to save your session locally."
        }

        Task {
            await syncService.sync(session: session)
        }
    }

    private func refreshReminders() async {
        session.profile.notificationPermissionStatus = await reminderScheduler.synchronizeReminders(for: session.recurringItems, profile: session.profile)
        saveSession()
    }

    static func makeWelcomeThread() -> ChatThread {
        ChatThread(
            id: UUID(),
            title: "New chat",
            createdAt: .now,
            updatedAt: .now,
            messages: [
                ChatMessage(
                    id: UUID(),
                    role: .assistant,
                    body: "How can I help you track your recurring income or costs today?",
                    createdAt: .now
                )
            ],
            pendingDraft: nil
        )
    }
}
