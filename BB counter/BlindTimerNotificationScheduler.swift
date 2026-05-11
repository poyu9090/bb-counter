import Foundation
import UserNotifications

enum BlindTimerNotificationScheduler {
	static func schedule(endDate: Date?, nextBlindText: String, reminderSeconds: Int = 60) {
		guard let endDate else {
			cancel()
			return
		}
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
			guard granted else { return }
			cancel()
			let now = Date()
			if endDate.timeIntervalSince(now) > TimeInterval(reminderSeconds + 5) {
				addNotification(
					id: "blind.timer.reminder",
					title: NSLocalizedString("notification.reminder_title", comment: ""),
					body: String(format: NSLocalizedString("notification.reminder_body", comment: ""), nextBlindText),
					date: endDate.addingTimeInterval(-TimeInterval(reminderSeconds))
				)
			}
			addNotification(
				id: "blind.timer.advance",
				title: NSLocalizedString("notification.advance_title", comment: ""),
				body: String(format: NSLocalizedString("notification.advance_body", comment: ""), nextBlindText),
				date: endDate
			)
		}
	}

	static func cancel() {
		UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
			"blind.timer.reminder",
			"blind.timer.advance"
		])
	}

	private static func addNotification(id: String, title: String, body: String, date: Date) {
		let interval = date.timeIntervalSinceNow
		guard interval > 1 else { return }
		let content = UNMutableNotificationContent()
		content.title = title
		content.body = body
		content.sound = .default
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
		let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
		UNUserNotificationCenter.current().add(request)
	}
}
