import SwiftUI
import UIKit
import UserNotifications

struct NotificationPermissionView: View {
    @Bindable var model: AppModel
    let onContinue: () -> Void

    @State private var isRequesting = false

    private struct Benefit {
        let icon: String
        let title: String
        let subtitle: String
    }

    private let benefits: [Benefit] = [
        Benefit(icon: "bell.badge", title: "Upcoming bills", subtitle: "Know before a charge hits your account"),
        Benefit(icon: "dollarsign.circle", title: "Paycheck reminders", subtitle: "Get notified when income is due"),
        Benefit(icon: "arrow.clockwise.circle", title: "Expiring subscriptions", subtitle: "Decide whether to renew before you're charged"),
        Benefit(icon: "chart.bar", title: "Monthly summary", subtitle: "A quick snapshot of your cashflow")
    ]

    var body: some View {
        VStack(spacing: 0) {

            // Header — left-aligned
            VStack(alignment: .leading, spacing: 0) {
                Text("Stay on top of your finances")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)

                Text("Enable notifications so MoneyGoWhere can keep you informed.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 36)

            // Benefits — left-aligned
            VStack(spacing: 16) {
                ForEach(benefits, id: \.title) { benefit in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: benefit.icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.brandGreen)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(benefit.title)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(benefit.subtitle)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    requestPermission()
                } label: {
                    Group {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("ENABLE NOTIFICATIONS")
                                .brandPrimaryButton(isPaywall: false, isDisabled: false)
                        }
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle(isPaywall: false, isDisabled: false))
                .disabled(isRequesting)

                Button("Maybe later") {
                    onContinue()
                }
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func requestPermission() {
        isRequesting = true
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            let currentStatus = await center.notificationSettings().authorizationStatus
            if currentStatus == .denied {
                // System won't re-prompt — send user to app's notification settings page
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    await UIApplication.shared.open(url)
                }
                isRequesting = false
                return
            }
            // .notDetermined → system shows the permission dialog and waits for response
            // .authorized / .provisional / .ephemeral → returns immediately with current grant
            let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            model.session.profile.notificationPermissionStatus = granted ? .authorized : .denied
            isRequesting = false
            onContinue()
        }
    }
}
