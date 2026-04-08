import Observation
import SwiftUI

struct ChatView: View {
    @Bindable var model: AppModel
    var hideMediaControls: Bool = false
    @FocusState private var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            conversationArea
            composer
        }
        .background(Color.bgBase)
    }

    private var conversationArea: some View {
        ScrollView {
            VStack(spacing: 16) {
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
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }

    private var composer: some View {
        VStack(spacing: 12) {
            if model.isReadOnly {
                Text("Your trial has ended. You can still review records, but adding or editing items is locked until you subscribe.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if hideMediaControls {
                // Compact overlay layout: send button floats over the text field
                ZStack(alignment: .bottomTrailing) {
                    TextField(
                        "e.g. Netflix Subscription $20 a month",
                        text: $model.composerText,
                        prompt: Text("e.g. Netflix Subscription $20 a month").foregroundStyle(Color.white.opacity(0.45)),
                        axis: .vertical
                    )
                    .lineLimit(1...5)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(Color.accentBlue)
                    .disabled(model.isReadOnly)
                    .focused($composerFocused)
                    .submitLabel(.send)
                    .onSubmit { submitAndDismiss() }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 48)
                    sendButton
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.separatorDark, lineWidth: 1)
                        .background(Color.bgSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .contentShape(Rectangle())
                .onTapGesture { composerFocused = true }
            } else {
                // Standard layout: text field + icons + send button on separate row
                VStack(alignment: .leading, spacing: 14) {
                    TextField(
                        "e.g. Netflix Subscription $20 a month",
                        text: $model.composerText,
                        prompt: Text("e.g. Netflix Subscription $20 a month").foregroundStyle(Color.white.opacity(0.45)),
                        axis: .vertical
                    )
                    .lineLimit(3...5)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(Color.accentBlue)
                    .disabled(model.isReadOnly)
                    .focused($composerFocused)
                    .submitLabel(.send)
                    .onSubmit { submitAndDismiss() }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        HStack(spacing: 8) {
                            disabledComposerIcon("photo")
                            disabledComposerIcon("paperclip")
                            disabledComposerIcon("mic")
                        }
                        Spacer()
                        sendButton
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.separatorDark, lineWidth: 1)
                        .background(Color.bgSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .contentShape(Rectangle())
                .onTapGesture { composerFocused = true }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.bgBase)
    }

    private func submitAndDismiss() {
        model.submitComposer()
        composerFocused = false
    }

    private var sendButton: some View {
        let isEmpty = model.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Button {
            submitAndDismiss()
        } label: {
            Image(systemName: "arrow.up")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Color.brandGreen.opacity(isEmpty || model.isReadOnly ? 0.35 : 1),
                    in: Circle()
                )
        }
        .disabled(isEmpty || model.isReadOnly)
    }

    private func disabledComposerIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.textSecondary.opacity(0.6))
            .frame(width: 32, height: 32)
            .background(Color.bgSurfaceRaised, in: Circle())
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
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(message.role == .system ? Color.textSecondary : .white)
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
            return Color.accentBlue.opacity(0.30)
        case .assistant:
            return Color.bgSurfaceRaised
        case .system:
            return Color.bgSurfaceRaised
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
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(draft.readyForConfirmation ? Color.brandGreen : .white)
            draftRow("Title", value: draft.title ?? "Missing")
            draftRow("Amount", value: draft.amount?.formatted(localeIdentifier: profile.localeIdentifier) ?? "Missing")
            draftRow("Cadence", value: draft.cadence?.displayTitle ?? "Missing")
            draftRow("Next due", value: draft.nextDueDate?.formattedMonthDay() ?? "Missing")
            draftRow("Type", value: draft.itemType?.displayTitle ?? "Missing")

            HStack {
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .tint(Color.textSecondary)

                Spacer()

                Button("Confirm save") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandGreen)
                .disabled(!draft.readyForConfirmation)
            }
        }
        .padding(18)
        .background(Color.bgSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func draftRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
