import Observation
import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var model: AppModel
    @State private var stepIndex = 0
    @State private var profile = UserProfile.empty
    @State private var firstItem = RecurringItemFormState.blank(defaultCurrencyCode: UserProfile.empty.defaultCurrencyCode, paymentMethod: "")
    @State private var selectedPaywallPlan: SubscriptionPlan = .yearly

    private let supportedCurrencies = ["USD", "SGD", "EUR", "GBP", "JPY"]

    var body: some View {
        VStack(spacing: 24) {
            header
            progress
            currentStep
            controls
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(red: 0.93, green: 0.97, blue: 0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            if profile.displayName.isEmpty {
                profile = model.session.profile
                firstItem = .blank(defaultCurrencyCode: profile.defaultCurrencyCode, paymentMethod: profile.defaultPaymentMethodLabel)
                firstItem.nextDueDate = Calendar.current.startOfDay(for: .now)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MoneyGoWhere")
                .font(.largeTitle.bold())
            Text("Track recurring cashflow through chat, stay ahead of upcoming bills, and keep your dashboard in sync with what matters.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(index <= stepIndex ? Color.accentColor : Color.gray.opacity(0.2))
                    .frame(height: 6)
            }
        }
    }

    @ViewBuilder
    private var currentStep: some View {
        switch stepIndex {
        case 0:
            introStep
        case 1:
            profileStep
        case 2:
            preferencesStep
        case 3:
            firstItemStep
        case 4:
            previewStep
        default:
            paywallStep
        }
    }

    private var introStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureCard(title: "Chat-first logging", subtitle: "Say \"ChatGPT plus 20 dollars monthly on the 15th\" and the app turns it into a structured recurring item.", symbol: "message.badge.waveform")
            featureCard(title: "Calendar-led dashboard", subtitle: "See when income lands, when bills hit, and how the month nets out.", symbol: "calendar")
            featureCard(title: "Memory-aware reminders", subtitle: "Persist pay dates, billing schedules, and payment methods so the app gets faster over time.", symbol: "brain.head.profile")
        }
    }

    private var profileStep: some View {
        VStack(spacing: 20) {
            formCard {
                TextField("Your display name", text: $profile.displayName)
                    .textInputAutocapitalization(.words)
                TextField(
                    "Email (optional)",
                    text: Binding(
                        get: { profile.email ?? "" },
                        set: { profile.email = $0.isEmpty ? nil : $0 }
                    )
                )
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Locale identifier", text: $profile.localeIdentifier)
                    .textInputAutocapitalization(.never)
            }

            formCard {
                Picker("Default currency", selection: $profile.defaultCurrencyCode) {
                    ForEach(supportedCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var preferencesStep: some View {
        VStack(spacing: 20) {
            formCard {
                TextField("Default payment method label (optional)", text: $profile.defaultPaymentMethodLabel)
                    .textInputAutocapitalization(.words)
                Toggle("Opt in to anonymized aggregate learning", isOn: $profile.aggregateLearningConsent)
                Text("Aggregate learning improves catalog defaults, popularity rankings, and autofill confidence without training on raw user chats.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var firstItemStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add your first recurring item")
                    .font(.title2.bold())
                Text("Start with a subscription, salary, or bill so MoneyGoWhere can immediately show value in chat and dashboard.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    TextField("Search or name", text: $firstItem.title)
                        .textFieldStyle(.roundedBorder)

                    if !firstItem.title.isEmpty {
                        suggestionStrip
                    }

                    HStack {
                        TextField("Amount", text: $firstItem.amountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        Picker("Currency", selection: $firstItem.currencyCode) {
                            ForEach(supportedCurrencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .frame(maxWidth: 120)
                    }

                    Picker("Type", selection: $firstItem.itemType) {
                        ForEach(RecurringItemType.allCases) { type in
                            Text(type.displayTitle).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Cadence", selection: $firstItem.cadence) {
                        ForEach(RecurrenceCadence.allCases) { cadence in
                            Text(cadence.displayTitle).tag(cadence)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker("Next due date", selection: $firstItem.nextDueDate, displayedComponents: .date)
                    TextField("Category", text: $firstItem.category)
                        .textFieldStyle(.roundedBorder)
                    TextField("Payment method label", text: $firstItem.paymentMethodLabel)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var suggestionStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Smart suggestions")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(model.catalogService.autocomplete(query: firstItem.title)) { suggestion in
                        Button {
                            firstItem.title = suggestion.title
                            firstItem.merchant = suggestion.title
                            firstItem.category = suggestion.category
                            firstItem.symbolName = suggestion.symbolName
                            firstItem.cadence = suggestion.cadence
                            if firstItem.amountText.isEmpty,
                               let amount = suggestion.defaultPricing[firstItem.currencyCode] ?? suggestion.defaultPricing[profile.defaultCurrencyCode] ?? suggestion.defaultPricing["USD"] {
                                firstItem.amountText = amount.description
                            }
                            if suggestion.category == "Income" {
                                firstItem.itemType = .income
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: suggestion.symbolName)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(suggestion.category)
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var previewStep: some View {
        let item = buildFirstItem()
        let projectedHomeAmount = item?.homeAmount ?? .zero(currencyCode: profile.defaultCurrencyCode)

        return VStack(alignment: .leading, spacing: 16) {
            Text("Immediate preview")
                .font(.title2.bold())
            Text("This is the first value moment you will unlock before the paywall.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                summaryRow(title: "Default currency", value: profile.defaultCurrencyCode)
                summaryRow(title: "First recurring item", value: item?.title ?? "Missing")
                summaryRow(title: "Projected monthly impact", value: projectedHomeAmount.formatted(localeIdentifier: profile.localeIdentifier))
                summaryRow(title: "Dashboard focus", value: "Calendar + recurring timeline")
            }
            .padding(20)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var paywallStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Start your free trial")
                .font(.title2.bold())
            Text("Unlock chat logging, dashboard editing, reminders, and premium insights for 7 days before the subscription begins.")
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(model.subscriptionService.offerings) { offering in
                    Button {
                        selectedPaywallPlan = offering.plan
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(offering.title)
                                    .font(.headline)
                                Text(offering.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(offering.priceLabel)
                                .font(.headline)
                            Image(systemName: selectedPaywallPlan == offering.plan ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedPaywallPlan == offering.plan ? Color.accentColor : Color.secondary)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selectedPaywallPlan == offering.plan ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Restore purchases") {
                model.restorePurchases()
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack {
            if stepIndex > 0 {
                Button("Back") {
                    withAnimation {
                        stepIndex -= 1
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button(stepIndex == 5 ? "Start 7-day trial" : "Continue") {
                continueFlow()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canContinue)
        }
        .padding(.top, 8)
    }

    private var canContinue: Bool {
        switch stepIndex {
        case 0:
            true
        case 1:
            !profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !profile.defaultCurrencyCode.isEmpty
                && !profile.localeIdentifier.isEmpty
        case 2:
            true
        case 3:
            buildFirstItem() != nil
        case 4:
            buildFirstItem() != nil
        default:
            true
        }
    }

    private func continueFlow() {
        if stepIndex < 5 {
            withAnimation {
                stepIndex += 1
            }
            return
        }

        model.completeOnboarding(profile: profile, firstItem: buildFirstItem(), startTrialPlan: selectedPaywallPlan)
    }

    private func buildFirstItem() -> RecurringItem? {
        guard
            let amount = Decimal(string: firstItem.amountText.replacingOccurrences(of: ",", with: ".")),
            !firstItem.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !firstItem.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        let originalAmount = MoneyAmount(amount: amount, currencyCode: firstItem.currencyCode)
        let homeAmount = model.conversionService.convert(originalAmount, to: profile.defaultCurrencyCode)
        return RecurringItem(
            id: UUID(),
            title: firstItem.title,
            merchant: firstItem.merchant.isEmpty ? firstItem.title : firstItem.merchant,
            category: firstItem.category,
            symbolName: firstItem.symbolName,
            originalAmount: originalAmount,
            homeAmount: homeAmount,
            cadence: firstItem.cadence,
            nextDueDate: firstItem.nextDueDate,
            itemType: firstItem.itemType,
            paymentMethodLabel: firstItem.paymentMethodLabel.isEmpty ? nil : firstItem.paymentMethodLabel,
            reminder: ReminderSettings.disabled,
            source: .manual,
            status: .active,
            createdAt: .now,
            updatedAt: .now
        )
    }

    private func featureCard(title: String, subtitle: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .padding(20)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
