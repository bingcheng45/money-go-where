import Foundation
import UserNotifications

@MainActor
protocol ReminderScheduling {
    func synchronizeReminders(for items: [RecurringItem], profile: UserProfile) async -> NotificationPermissionStatus
}

struct LocalReminderScheduler: ReminderScheduling {
    func synchronizeReminders(for items: [RecurringItem], profile: UserProfile) async -> NotificationPermissionStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let status: NotificationPermissionStatus

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            status = .authorized
        case .denied:
            status = .denied
        case .notDetermined:
            // Permission must be requested via the dedicated onboarding screen, not inline.
            status = .unknown
        @unknown default:
            status = .unknown
        }

        guard status == .authorized else {
            return status
        }

        center.removeAllPendingNotificationRequests()

        for item in items where item.reminder.isEnabled && item.status == .active {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: item.nextDueDate.addingTimeInterval(TimeInterval(-86400 * item.reminder.daysBefore)))
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = "\(item.originalAmount.formatted()) due on \(item.nextDueDate.formattedMonthDay())"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
            try? await center.add(request)
        }

        return status
    }
}

