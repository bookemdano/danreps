//
//  DNotices.swift
//  danreps
//
//  Created by Daniel Francis on 2/11/25.
//


import UserNotifications

struct DNotices
{
    public static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permission granted")
            } else {
                print("Permission denied")
            }
        }
    }
    static func scheduleNotification(_ body: String, interval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        let notificationCenter = UNUserNotificationCenter.current()
        Task {
            do {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                print(settings)
                try await notificationCenter.add(request)
                print("Scheduling notification t:\(trigger) r:\(request)")
            } catch let error {
                print("Error scheduling notification: \(error)")
            }
        }

        /*
        await UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }*/
    }
}

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler() // Singleton instance

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("Received notification while in foreground: \(notification.request.content.body)")

        // Show alert, play sound, and badge the app
        completionHandler([.banner, .sound, .badge])
    }
}
