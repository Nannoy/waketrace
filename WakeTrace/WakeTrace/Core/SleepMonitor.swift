import Foundation
import AppKit

// Observes NSWorkspace sleep/wake notifications and publishes session boundary timestamps.
@MainActor
final class SleepMonitor {
    weak var delegate: SleepMonitorDelegate?

    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    private var sessionSleepStart: Date?

    func start() {
        let nc = NSWorkspace.shared.notificationCenter

        sleepObserver = nc.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWillSleep()
            }
        }

        wakeObserver = nc.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleDidWake()
            }
        }
    }

    func stop() {
        if let o = sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(o) }
        if let o = wakeObserver  { NSWorkspace.shared.notificationCenter.removeObserver(o) }
        sleepObserver = nil
        wakeObserver = nil
    }

    private func handleWillSleep() {
        sessionSleepStart = Date()
        delegate?.sleepMonitorWillSleep(at: sessionSleepStart!)
    }

    private func handleDidWake() {
        let wakeTime = Date()
        guard let sleepStart = sessionSleepStart else {
            // Wake without a tracked sleep — happens on first launch if Mac was
            // already asleep when the app started. Record sleep start conservatively.
            delegate?.sleepMonitorDidWake(sleepStart: wakeTime.addingTimeInterval(-3600), wakeEnd: wakeTime)
            return
        }
        sessionSleepStart = nil
        delegate?.sleepMonitorDidWake(sleepStart: sleepStart, wakeEnd: wakeTime)
    }
}

@MainActor
protocol SleepMonitorDelegate: AnyObject {
    func sleepMonitorWillSleep(at date: Date)
    func sleepMonitorDidWake(sleepStart: Date, wakeEnd: Date)
}
