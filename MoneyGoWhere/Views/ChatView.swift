import Observation
import SwiftUI

struct ChatView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            conversationArea
            composer
        }
        .background(Color(.systemBackground))
    }

    private var conversationArea: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if model.activeThread.messages.count <= 1, model.activeThread.pendingDraft == nil {
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 54, height: 54)
                                .overlay(
                                    Image(systemName: "dollarsign")
                                        .font(.title3.weight(.bold))
                                )
                            Text("How can I help you?")
                                .font(.title2.weight(.bold))
                        }
                        .frame(minHeight: proxy.size.height - 40)
                    } else {
                        ForEach(model.activeThread.messages) { message in
                            MessageBubble(message: message)
                        }

                        if let draft = model.activeThread.pendingDraft {
                            DraftReviewCard(draft: draft, profile: model.session.profile, onConfirm: {
                                model.confirmPendingDraft()
                            }, onEdit: {
                                model.editPendingDraft()
                            })
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 12) {
            if model.isReadOnly {
                Text("Your trial has ended. You can still review records, but adding or editing items is locked until you subscribe.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 14) {
                TextField("Tell me your fixed cost or income here!", text: $model.composerText, axis: .vertical)
                    .lineLimit(3...5)
                    .disabled(model.isReadOnly)

                HStack {
                    HStack(spacing: 8) {
                        disabledComposerIcon("photo")
                        disabledComposerIcon("paperclip")
                        disabledComposerIcon("mic")
                    }
                    Spacer()
                    Button {
                        model.submitComposer()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(model.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isReadOnly ? Color.secondary : Color.accentColor)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray5), in: Circle())
                    }
                    .disabled(model.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isReadOnly)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private func disabledComposerIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary.opacity(0.6))
            .frame(width: 32, height: 32)
            .background(Color(.systemGray6), in: Circle())
            .opacity(0.7)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 48)
            }
            Text(message.body)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
            if message.role != .user {
                Spacer(minLength: 48)
            }
        }
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return Color.accentColor.opacity(0.12)
        case .assistant:
            return Color(.secondarySystemBackground)
        case .system:
            return Color.orange.opacity(0.14)
        }
    }
}

private struct DraftReviewCard: View {
    let draft: ExtractionDraft
    let profile: UserProfile
    let onConfirm: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(draft.readyForConfirmation ? "Ready to save" : "Waiting on more detail")
                .font(.headline)
            LabeledContent("Title", value: draft.title ?? "Missing")
            LabeledContent("Amount", value: draft.amount?.formatted(localeIdentifier: profile.localeIdentifier) ?? "Missing")
            LabeledContent("Cadence", value: draft.cadence?.displayTitle ?? "Missing")
            LabeledContent("Next due", value: draft.nextDueDate?.formattedMonthDay() ?? "Missing")
            LabeledContent("Type", value: draft.itemType?.displayTitle ?? "Missing")

            HStack {
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Confirm save") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!draft.readyForConfirmation)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

