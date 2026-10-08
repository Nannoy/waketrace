import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    // Action identifier for opening the report window
    static let openReportAction = "OPEN_REPORT"
    static let categoryID       = "SLEEP_REPORT"

    override init() {
        super.init()
        center.delegate = self
        registerActions()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    var hasPermission: Bool {
        get async {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Send

    func sendReport(_ report: SleepReport) async {
        guard await hasPermission else { return }

        let topFinding = report.findings.max(by: { $0.severity < $1.severity })
        guard let finding = topFinding, finding.severity >= .notice else { return }

        let content = UNMutableNotificationContent()
        content.title = "WakeTrace — \(report.nightLabel)"
        content.body = finding.headline
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.userInfo = ["sessionId": report.id.uuidString]

        let request = UNNotificationRequest(
            identifier: report.id.uuidString,
            content: content,
            trigger: nil  // deliver immediately
        )

        try? await center.add(request)
    }

    // MARK: - Delegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        // The app opens the report window via deeplink on notification tap.
        // NSApp activation is handled by the OS when the notification is tapped.
        handler()
    }

    // MARK: - Setup

    private func registerActions() {
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        center.setNotificationCategories([category])
    }
}
