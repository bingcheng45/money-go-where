import Observation
import SwiftUI

struct RecurringItemEditorView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private let currencies = ["USD", "SGD", "EUR", "GBP", "JPY"]
    private let categories = ["Subscriptions", "Entertainment", "Productivity", "Utilities", "Housing", "Transport", "Income", "Savings", "Insurance", "Health"]

    var body: some View {
        NavigationStack {
            if model.editorDraft != nil {
                let draft = Binding(
                    get: { model.editorDraft ?? .blank(defaultCurrencyCode: model.session.profile.defaultCurrencyCode, paymentMethod: model.session.profile.defaultPaymentMethodLabel) },
                    set: { model.editorDraft = $0 }
                )

                Form {
                    Section("Search") {
                        TextField("Search catalog or enter a name", text: draft.title)
                        let suggestions = model.catalogService.autocomplete(query: draft.wrappedValue.title)
                        if !suggestions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(suggestions) { suggestion in
                                        Button {
                                            apply(suggestion: suggestion, to: draft)
                                        } label: {
                                            Label(suggestion.title, systemImage: suggestion.symbolName)
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

                    Section("Basics") {
                        TextField("Title", text: draft.title)
                        TextField("Merchant", text: draft.merchant)
                        Picker("Category", selection: draft.category) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        TextField("SF Symbol", text: draft.symbolName)
                            .textInputAutocapitalization(.never)
                    }

                    Section("Money") {
                        TextField("Amount", text: draft.amountText)
                            .keyboardType(.decimalPad)
                        Picker("Currency", selection: draft.currencyCode) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        Picker("Type", selection: draft.itemType) {
                            ForEach(RecurringItemType.allCases) { type in
                                Text(type.displayTitle).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Schedule") {
                        Picker("Cadence", selection: draft.cadence) {
                            ForEach(RecurrenceCadence.allCases) { cadence in
                                Text(cadence.displayTitle).tag(cadence)
                            }
                        }
                        DatePicker("Next due date", selection: draft.nextDueDate, displayedComponents: .date)
                    }

                    Section("Payment and reminders") {
                        TextField("Payment method label", text: draft.paymentMethodLabel)
                        Toggle("Enable reminder", isOn: draft.remindersEnabled)
                        if draft.wrappedValue.remindersEnabled {
                            Stepper("Days before: \(draft.wrappedValue.reminderDaysBefore)", value: draft.reminderDaysBefore, in: 1...14)
                        }
                    }
                }
                .navigationTitle(model.editingItemID == nil ? "New recurring item" : "Edit recurring item")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            model.closeEditor()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            model.saveEditor()
                            dismiss()
                        }
                        .disabled(model.isReadOnly)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func apply(suggestion: CatalogEntry, to draft: Binding<RecurringItemFormState>) {
        draft.title.wrappedValue = suggestion.title
        draft.merchant.wrappedValue = suggestion.title
        draft.category.wrappedValue = suggestion.category
        draft.symbolName.wrappedValue = suggestion.symbolName
        draft.cadence.wrappedValue = suggestion.cadence
        if draft.wrappedValue.amountText.isEmpty,
           let amount = suggestion.defaultPricing[draft.wrappedValue.currencyCode] ?? suggestion.defaultPricing["USD"] {
            draft.amountText.wrappedValue = amount.description
        }
        if suggestion.category == "Income" {
            draft.itemType.wrappedValue = .income
        }
    }
}

