import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject, SleepMonitorDelegate {
    @Published var sessions: [SleepReport] = []
    @Published var selectedSession: SleepReport?
    @Published var isFirstLaunch: Bool = false
    @Published var currentBatteryLevel: Double = 0
    @Published var isCharging: Bool = false
    @Published var isAnalyzing: Bool = false

    private let monitor = SleepMonitor()
    private var batteryAtLastSleep: Double?
    private var wasChargingAtLastSleep: Bool = false
    private var batteryTimer: Timer?

    // MARK: - Computed

    var lastSession: SleepReport? { sessions.first }

    var hasBaseline: Bool { sessions.count >= 5 }

    var baseline: BaselineEngine.Baseline { BaselineEngine.compute(from: sessions) }
    var baselineDrainRate: Double? { baseline.drainRate }
    var baselineWakeRate: Double?  { baseline.wakeRate }

    // MARK: - Lifecycle

    init() {
        let stored = SessionStore.shared.load()
        sessions = stored.isEmpty ? MockData.history : stored
        refreshBattery()
        monitor.delegate = self
        monitor.start()

        batteryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshBattery() }
        }
    }

    func stop() {
        monitor.stop()
        batteryTimer?.invalidate()
        batteryTimer = nil
    }

    // MARK: - SleepMonitorDelegate

    nonisolated func sleepMonitorWillSleep(at date: Date) {
        Task { @MainActor in
            let snap = BatteryMonitor.snapshot()
            batteryAtLastSleep    = snap?.percentage
            wasChargingAtLastSleep = snap?.isCharging ?? false
            if let pct = snap?.percentage {
                currentBatteryLevel = pct
                isCharging = snap?.isCharging ?? false
            }
        }
    }

    nonisolated func sleepMonitorDidWake(sleepStart: Date, wakeEnd: Date) {
        Task { @MainActor in
            await analyzeSession(sleepStart: sleepStart, wakeEnd: wakeEnd)
        }
    }

    // MARK: - Session Analysis

    private func analyzeSession(sleepStart: Date, wakeEnd: Date) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let wakeSnap = BatteryMonitor.snapshot()
        let batteryWake   = wakeSnap?.percentage
        let chargingWake  = wakeSnap?.isCharging ?? false
        let wasCharging   = wasChargingAtLastSleep || chargingWake

        // Refresh live battery display
        if let pct = batteryWake {
            currentBatteryLevel = pct
            isCharging = chargingWake
        }

        // Run log query off main thread
        let (entries, assertions) = await Task.detached(priority: .userInitiated) {
            let entries    = LogReader.readSleepWakeEvents(from: sleepStart, to: wakeEnd)
            let assertions = LogReader.readCurrentAssertions()
            return (entries, assertions)
        }.value

        let builder = SessionBuilder(sleepStart: sleepStart, wakeEnd: wakeEnd)
        let session = builder.build(
            sleepWakeEntries: entries,
            batteryAtSleep: batteryAtLastSleep,
            batteryAtWake: batteryWake,
            wasCharging: wasCharging,
            rawAssertions: assertions
        )

        let findings = SessionAnalyzer(session: session).analyze()
        let report   = session.toReport(
            findings: findings,
            baselineDrainRate: baselineDrainRate,
            baselineWakeRate: baselineWakeRate
        )

        sessions = SessionStore.shared.append(report, to: sessions)
        selectedSession = report

        await NotificationManager.shared.sendReport(report)
    }

    // MARK: - Helpers

    func refreshBattery() {
        if let snap = BatteryMonitor.snapshot() {
            currentBatteryLevel = snap.percentage
            isCharging = snap.isCharging
        }
    }

    func openReport(_ session: SleepReport) {
        selectedSession = session
    }
}
