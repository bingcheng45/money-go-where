import Observation
import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var model: AppModel
    @State private var stepIndex = 0
    @State private var isNavigating = false
    @State private var goingForward = true
    @State private var introItemsVisible: [Bool] = Array(repeating: false, count: 4)
    @State private var profile = UserProfile.empty
    @State private var firstItem = RecurringItemFormState.blank(defaultCurrencyCode: UserProfile.empty.defaultCurrencyCode, paymentMethod: "")
    @State private var selectedPaywallPlan: SubscriptionPlan = .yearly
    @State private var paywallOfferings: [SubscriptionOffering] = []
    @FocusState private var focusedField: String?

    private let supportedCurrencies = ["USD", "SGD", "EUR", "GBP", "JPY"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if stepIndex > 0 {
                    Button {
                        guard !isNavigating else { return }
                        isNavigating = true
                        goingForward = false
                        withAnimation(.easeInOut(duration: 0.3)) { stepIndex -= 1 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { isNavigating = false }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 28, height: 28)
                    }
                } else {
                    Color.clear.frame(width: 28, height: 28)
                }
                progressBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollView {
                currentStep
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    .transition(.asymmetric(
                        insertion: .move(edge: goingForward ? .trailing : .leading),
                        removal: .move(edge: goingForward ? .leading : .trailing)
                    ))
                    .id(stepIndex)
            }

            brandControls
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
        }
        .background(Color.bgBase.ignoresSafeArea())
        .onAppear {
            if profile.displayName.isEmpty {
                // Copy locale/currency/identity from the session — but NOT name or email,
                // which the user must fill in themselves.
                var seeded = model.session.profile
                seeded.displayName = ""
                seeded.email = nil
                profile = seeded
                firstItem = .blank(defaultCurrencyCode: profile.defaultCurrencyCode, paymentMethod: profile.defaultPaymentMethodLabel)
                firstItem.nextDueDate = Calendar.current.startOfDay(for: .now)
            }
        }
        .task {
            if let loaded = try? await model.subscriptionService.offerings {
                paywallOfferings = loaded
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.bgSurface)
                    .frame(height: 6)
                Capsule()
                    .fill(Color.brandGreen)
                    .frame(width: geo.size.width * CGFloat(stepIndex + 1) / 7.0, height: 6)
                    .animation(.easeOut(duration: 0.3), value: stepIndex)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Step Router

    @ViewBuilder
    private var currentStep: some View {
        switch stepIndex {
        case 0: authStep
        case 1: introStep
        case 2: profileStep
        case 3: preferencesStep
        case 4: firstItemStep
        case 5: previewStep
        default: paywallStep
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var brandControls: some View {
        if stepIndex == 0 {
            authControls
        } else {
            Button(action: continueFlow) {
                Text(stepIndex == 6 ? "START FREE TRIAL" : "CONTINUE")
                    .brandPrimaryButton(isPaywall: stepIndex == 6, isDisabled: !canContinue)
            }
            .buttonStyle(BrandPrimaryButtonStyle(isPaywall: stepIndex == 6, isDisabled: !canContinue))
            .disabled(!canContinue)
        }
    }

    // MARK: - Step 0: Auth

    private var authStep: some View {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .frame(width: 80, height: 80)

            Text("MoneyGoWhere")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical, alignment: .center)
    }

    private var authControls: some View {
        VStack(spacing: 12) {
            Button(action: signInWithApple) {
                Group {
                    if model.isSigningIn {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Label {
                            Text("Sign up with Apple")
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                        } icon: {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(AuthButtonStyle())
            .disabled(model.isSigningIn)

            Button(action: signInWithGoogle) {
                HStack(spacing: 10) {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("Sign up with Google")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.bgBase)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(white: 0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(AuthButtonStyle())

            Button(action: continueFlow) {
                Text("Skip for now")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            if let error = model.authError {
                Text(error)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.red.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
        }
    }

    private func signInWithApple() {
        Task { @MainActor in
            guard let appleProfile = await model.signInWithApple() else { return }
            // Record the Apple user ID for credential state tracking — leave name/email blank for user to fill in
            profile.appleUserID = appleProfile.appleUserID
            continueFlow()
        }
    }

    private func signInWithGoogle() {
        // TODO: wire to AccountService Google Sign In when protocol is implemented
        continueFlow()
    }

    // MARK: - Step 1: Intro

    private var introStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("MoneyGoWhere")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Know where every dollar goes. Before it's gone.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            .opacity(introItemsVisible[0] ? 1 : 0)
            .offset(y: introItemsVisible[0] ? 0 : -16)

            VStack(spacing: 12) {
                introRow(
                    title: "Chat-first logging",
                    subtitle: "Say \"ChatGPT plus 20 dollars monthly\" and the app turns it into a structured item.",
                    symbol: "message.fill"
                )
                .opacity(introItemsVisible[1] ? 1 : 0)
                .offset(y: introItemsVisible[1] ? 0 : -16)

                introRow(
                    title: "Calendar-led dashboard",
                    subtitle: "See when income lands, when bills hit, and how the month nets out.",
                    symbol: "calendar"
                )
                .opacity(introItemsVisible[2] ? 1 : 0)
                .offset(y: introItemsVisible[2] ? 0 : -16)

                introRow(
                    title: "Memory-aware reminders",
                    subtitle: "Persist pay dates, billing schedules and payment methods so the app gets faster over time.",
                    symbol: "bell.fill"
                )
                .opacity(introItemsVisible[3] ? 1 : 0)
                .offset(y: introItemsVisible[3] ? 0 : -16)
            }
        }
        .onAppear {
            for index in 0 ..< 4 {
                let delay = Double(index) * 0.12
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        introItemsVisible[index] = true
                    }
                }
            }
        }
    }

    private func introRow(title: String, subtitle: String, symbol: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.brandGreen.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.brandGreen)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Step 1: Profile

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeading("What's your name?", subtitle: "We'll personalise your experience.")

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    brandField("Display name", text: $profile.displayName, isValid: isValidDisplayName)
                        .textInputAutocapitalization(.words)
                    if !profile.displayName.isEmpty && !isValidDisplayName {
                        Text("Must be at least 4 characters")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.red.opacity(0.8))
                            .padding(.horizontal, 4)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    brandField(
                        "Email (optional)",
                        text: Binding(
                            get: { profile.email ?? "" },
                            set: { profile.email = $0.isEmpty ? nil : $0 }
                        ),
                        isValid: profile.email.map { isValidEmail($0) } ?? false
                    )
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    if let email = profile.email, !email.isEmpty, !isValidEmail(email) {
                        Text("Enter a valid email address")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.red.opacity(0.8))
                            .padding(.horizontal, 4)
                    }
                }
                // Locale is auto-detected from Locale.current (device Language & Region setting)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("DEFAULT CURRENCY")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                Picker("Default currency", selection: $profile.defaultCurrencyCode) {
                    ForEach(supportedCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color.brandGreen)
            }
        }
    }

    // MARK: - Step 2: Preferences

    private var preferencesStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeading("A few preferences", subtitle: "You can change these any time in settings.")

            VStack(spacing: 12) {
                brandField("Default payment method (optional)", text: $profile.defaultPaymentMethodLabel)
                    .textInputAutocapitalization(.words)

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Help improve catalog defaults", isOn: $profile.aggregateLearningConsent)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(Color.brandGreen)
                    Text("Aggregate learning improves catalog defaults, popularity rankings, and autofill confidence without training on raw user chats.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(16)
                .background(Color.bgSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: - Step 3: First Item

    private var firstItemStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                stepHeading("Add your first item", subtitle: "Start with a subscription, salary, or bill.")

                VStack(spacing: 12) {
                    brandField("Search or name", text: $firstItem.title, isValid: !firstItem.title.isEmpty)

                    if !firstItem.title.isEmpty {
                        suggestionStrip
                    }

                    HStack(spacing: 10) {
                        brandField("Amount", text: $firstItem.amountText, isValid: !firstItem.amountText.isEmpty)
                            .keyboardType(.decimalPad)
                        Picker("Currency", selection: $firstItem.currencyCode) {
                            ForEach(supportedCurrencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .frame(maxWidth: 110)
                        .tint(Color.brandGreen)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("TYPE")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textSecondary)
                        Picker("Type", selection: $firstItem.itemType) {
                            ForEach(RecurringItemType.allCases) { type in
                                Text(type.displayTitle).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Color.brandGreen)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CADENCE")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textSecondary)
                        Picker("Cadence", selection: $firstItem.cadence) {
                            ForEach(RecurrenceCadence.allCases) { cadence in
                                Text(cadence.displayTitle).tag(cadence)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Color.brandGreen)
                    }

                    DatePicker("Next due date", selection: $firstItem.nextDueDate, displayedComponents: .date)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(Color.brandGreen)

                    brandField("Category", text: $firstItem.category, isValid: !firstItem.category.isEmpty)
                    brandField("Payment method label", text: $firstItem.paymentMethodLabel)
                }
            }
        }
    }

    private var suggestionStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SUGGESTIONS")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textSecondary)
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
                               let amount = suggestion.defaultPricing[firstItem.currencyCode]
                                   ?? suggestion.defaultPricing[profile.defaultCurrencyCode]
                                   ?? suggestion.defaultPricing["USD"] {
                                firstItem.amountText = amount.description
                            }
                            if suggestion.category == "Income" {
                                firstItem.itemType = .income
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: suggestion.symbolName)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.accentBlue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text(suggestion.category)
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.bgSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.accentBlue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Step 4: Preview

    private var previewStep: some View {
        let item = buildFirstItem()
        let projectedHomeAmount = item?.homeAmount ?? .zero(currencyCode: profile.defaultCurrencyCode)

        return VStack(alignment: .leading, spacing: 16) {
            stepHeading("Here's your preview", subtitle: "This is the value moment before the paywall.")

            VStack(spacing: 0) {
                previewRow(label: "Default currency", value: profile.defaultCurrencyCode, isAmount: false)
                Divider().background(Color.separatorDark)
                previewRow(label: "First recurring item", value: item?.title ?? "Missing", isAmount: false)
                Divider().background(Color.separatorDark)
                previewRow(label: "Projected monthly impact", value: projectedHomeAmount.formatted(localeIdentifier: profile.localeIdentifier), isAmount: true)
                Divider().background(Color.separatorDark)
                previewRow(label: "Dashboard focus", value: "Calendar + recurring timeline", isAmount: false)
            }
            .background(Color.bgSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func previewRow(label: String, value: String, isAmount: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(isAmount ? Color.brandGreen : .white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Step 5: Paywall

    private var paywallStep: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color.accentPurpleDeep, Color(red: 0.106, green: 0.106, blue: 0.227)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center) {
                    Text("Unlock MoneyGoWhere")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("PRO")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.bgBase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.brandGreen, in: Capsule())
                }

                Text("7 days free, then choose your plan. Cancel anytime in the App Store.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.textSecondary)

                VStack(spacing: 10) {
                    ForEach(paywallOfferings) { offering in
                        paywallPlanRow(offering: offering)
                    }
                }

                Button("Restore purchases") {
                    model.restorePurchases()
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private func paywallPlanRow(offering: SubscriptionOffering) -> some View {
        let isSelected = selectedPaywallPlan == offering.plan
        return Button {
            selectedPaywallPlan = offering.plan
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(offering.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        if offering.plan == .yearly {
                            Text("MOST POPULAR")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentBlue, in: Capsule())
                        }
                    }
                    Text(offering.subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Text(offering.priceLabel)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                Color.bgSurface.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.accentBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shared Helpers

    private func stepHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color.textSecondary)
        }
    }

    private func brandField(_ placeholder: String, text: Binding<String>, isValid: Bool = false) -> some View {
        HStack {
            TextField(
                placeholder,
                text: text,
                prompt: Text(placeholder).foregroundStyle(Color.white.opacity(0.45))
            )
            .font(.system(size: 17, weight: .regular, design: .rounded))
            .foregroundStyle(.white)
            .tint(Color.accentBlue)
            if isValid {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.brandGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.bgSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Logic (unchanged)

    private var isValidDisplayName: Bool {
        // TODO: add async API call to validate display name uniqueness/availability once backend exists
        profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private var canContinue: Bool {
        switch stepIndex {
        case 0, 1, 3: true
        case 2:
            isValidDisplayName
                && !profile.defaultCurrencyCode.isEmpty
                && (profile.email == nil || profile.email.map { isValidEmail($0) } ?? true)
        case 4, 5: buildFirstItem() != nil
        default: true
        }
    }

    private func continueFlow() {
        guard !isNavigating else { return }
        if stepIndex < 6 {
            isNavigating = true
            goingForward = true
            withAnimation(.easeInOut(duration: 0.3)) { stepIndex += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { isNavigating = false }
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
}
