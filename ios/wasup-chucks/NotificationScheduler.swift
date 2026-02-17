//
//  NotificationScheduler.swift
//  wasup-chucks
//
//  Local notification scheduling for favorite menu items.
//

import Foundation
import UserNotifications

final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    func scheduleTest(completion: @escaping (String) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied:
                DispatchQueue.main.async { completion("denied") }
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        self.addTestNotification(center: center, completion: completion)
                    } else {
                        DispatchQueue.main.async { completion("denied") }
                    }
                }
            default:
                self.addTestNotification(center: center, completion: completion)
            }
        }
    }

    private func addTestNotification(center: UNUserNotificationCenter, completion: @escaping (String) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = "Lunch has your favorites!"
        content.body = "Pizza, Chicken Parmesan at Chuck's today."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        center.add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion("error: \(error.localizedDescription)")
                } else {
                    completion("scheduled")
                }
            }
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func requestPermissionIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            }
        }
    }

    func reschedule(menus: MenuResponse, favoriteItems: Set<String>, favoriteKeywords: Set<String>) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let matches = findFavoriteMatches(in: menus, favoriteItems: favoriteItems, favoriteKeywords: favoriteKeywords)
        guard !matches.isEmpty else { return }

        let calendar = CedarvilleTime.calendar
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = calendar.timeZone

        for match in matches {
            guard let date = dateFormatter.date(from: match.dateKey) else { continue }

            let weekday = calendar.component(.weekday, from: date)
            let schedule = MealSchedule.schedule(for: weekday)
            guard let mealSchedule = schedule.first(where: { $0.phase == match.meal }) else { continue }

            // Notification time = 1 hour before meal start
            guard var notifyDate = calendar.date(bySettingHour: mealSchedule.startHour, minute: mealSchedule.startMinute, second: 0, of: date) else { continue }
            notifyDate = notifyDate.addingTimeInterval(-3600)

            guard notifyDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.sound = .default

            let mealName = match.meal.rawValue
            content.title = "\(mealName) has your favorites!"

            let itemNames = match.matchedItems
            if itemNames.count <= 2 {
                content.body = "\(itemNames.joined(separator: ", ")) at Chuck's today."
            } else {
                let shown = itemNames.prefix(2).joined(separator: ", ")
                content.body = "\(shown) +\(itemNames.count - 2) more at Chuck's today."
            }

            // Use device calendar so the trigger fires at the correct local time
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let requestID = "fav-\(match.dateKey)-\(mealName)"
            let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification \(requestID): \(error)")
                }
            }
        }
    }
}
