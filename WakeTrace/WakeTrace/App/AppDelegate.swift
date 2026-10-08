import AppKit

extension Notification.Name {
    static let openOnboardingIfNeeded = Notification.Name("WakeTrace.openOnboardingIfNeeded")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") else { return }
        // Short delay so SwiftUI scenes finish initializing before we open a new window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            NotificationCenter.default.post(name: .openOnboardingIfNeeded, object: nil)
        }
    }
}
