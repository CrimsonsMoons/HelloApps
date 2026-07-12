import Foundation
import UserNotifications

enum NotificationManager {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleImmediateNotification(title: String, body: String) async {
        let granted = await requestPermission()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func scheduleTestNotification() async {
        let granted = await requestPermission()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Aevra"
        content.body = "Your smart notification test worked."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
