import UserNotifications
import UIKit

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            return try await center.requestAuthorization(options: options)
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func isAuthorized() async -> Bool {
        let status = await getAuthorizationStatus()
        return status == .authorized || status == .provisional
    }

    // MARK: - Schedule Event Reminder
    func scheduleEventReminder(
        id: String,
        title: String,
        body: String,
        date: Date,
        minutesBefore: Int = Constants.Notifications.defaultReminderMinutes
    ) async {
        guard await isAuthorized() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.event.rawValue

        let triggerDate = date.adding(.minute, value: -minutesBefore)
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "event_\(id)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    // MARK: - Schedule Task Reminder
    func scheduleTaskReminder(
        id: String,
        title: String,
        dueDate: Date
    ) async {
        guard await isAuthorized() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Due"
        content.body = title
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.task.rawValue

        // Remind at start of the due day
        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: dueDate
        )
        components.hour = Constants.Notifications.aiTaskReminderHour
        components.minute = 0

        guard let triggerDate = Calendar.current.date(from: components),
              triggerDate > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task_\(id)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule task notification: \(error)")
        }
    }

    // MARK: - Schedule AI Task Reminder
    func scheduleAITaskReminder(
        goalId: String,
        taskId: String,
        title: String,
        scheduledDate: Date
    ) async {
        guard await isAuthorized() else { return }

        let content = UNMutableNotificationContent()
        content.title = "AI Schedule: Task Due"
        content.body = title
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.aiTask.rawValue
        content.userInfo = ["goalId": goalId, "taskId": taskId]

        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: scheduledDate
        )
        components.hour = Constants.Notifications.aiTaskReminderHour
        components.minute = 0

        guard let triggerDate = Calendar.current.date(from: components),
              triggerDate > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "ai_task_\(goalId)_\(taskId)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule AI task notification: \(error)")
        }
    }

    // MARK: - Cancel Notifications
    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelEventNotification(eventId: String) {
        cancelNotification(id: "event_\(eventId)")
    }

    func cancelTaskNotification(taskId: String) {
        cancelNotification(id: "task_\(taskId)")
    }

    func cancelAITaskNotification(goalId: String, taskId: String) {
        cancelNotification(id: "ai_task_\(goalId)_\(taskId)")
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Get Pending Notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    // MARK: - Badge Management
    func setBadgeCount(_ count: Int) async {
        do {
            try await center.setBadgeCount(count)
        } catch {
            print("Failed to set badge count: \(error)")
        }
    }

    func clearBadge() async {
        await setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle notification tap - post notification for views to handle
        NotificationCenter.default.post(
            name: .didTapNotification,
            object: nil,
            userInfo: userInfo
        )

        completionHandler()
    }
}

// MARK: - Notification Categories
enum NotificationCategory: String {
    case event = "EVENT"
    case task = "TASK"
    case aiTask = "AI_TASK"
    case goal = "GOAL"
}

// MARK: - Notification Names
extension Notification.Name {
    static let didTapNotification = Notification.Name("didTapNotification")
}
