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
    @Published var activeAssertions: [String] = []  // process names holding sleep assertions

    private let monitor = SleepMonitor()
    private var batteryAtLastSleep: Double?
    private var wasChargingAtLastSleep: Bool = false
    private var batteryTimer: Timer?
    private var assertionTimer: Timer?

    // MARK: - Computed

    var lastSession: SleepReport? { sessions.first }
    var hasBaseline: Bool { sessions.count >= 5 }
    var baseline: BaselineEngine.Baseline { BaselineEngine.compute(from: sessions) }
    var baselineDrainRate: Double? { baseline.drainRate }
    var baselineWakeRate: Double?  { baseline.wakeRate }

    // MARK: - Lifecycle

    init() {
        let stored = SessionStore.shared.load()
        sessions = stored
        refreshBattery()
        refreshAssertions()
        monitor.delegate = self
        monitor.start()

        // Background battery + assertion refresh
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshBattery() }
        }
        assertionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshAssertions() }
        }

        // If no stored sessions, try to load the most recent real session from logs
        if stored.isEmpty {
            Task { await retroactiveLoad() }
        }
    }

    func stop() {
        monitor.stop()
        batteryTimer?.invalidate()
        assertionTimer?.invalidate()
        batteryTimer = nil
        assertionTimer = nil
    }

    // MARK: - Retroactive load (first launch)

    private func retroactiveLoad() async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let boundary = await Task.detached(priority: .utility) {
            LogReader.mostRecentSleepBoundary()
        }.value

        guard let b = boundary else { return }
        await analyzeSession(sleepStart: b.sleepStart, wakeEnd: b.wakeEnd, batteryAtSleep: nil, batteryAtWake: nil, wasCharging: false)
    }

    // MARK: - SleepMonitorDelegate

    nonisolated func sleepMonitorWillSleep(at date: Date) {
        Task { @MainActor in
            let snap = BatteryMonitor.snapshot()
            batteryAtLastSleep     = snap?.percentage
            wasChargingAtLastSleep = snap?.isCharging ?? false
            if let pct = snap?.percentage {
                currentBatteryLevel = pct
                isCharging = snap?.isCharging ?? false
            }
        }
    }

    nonisolated func sleepMonitorDidWake(sleepStart: Date, wakeEnd: Date) {
        Task { @MainActor in
            let wakeSnap = BatteryMonitor.snapshot()
            await analyzeSession(
                sleepStart: sleepStart,
                wakeEnd: wakeEnd,
                batteryAtSleep: batteryAtLastSleep,
                batteryAtWake: wakeSnap?.percentage,
                wasCharging: wasChargingAtLastSleep || (wakeSnap?.isCharging ?? false)
            )
            refreshAssertions()
        }
    }

    // MARK: - Session Analysis

    private func analyzeSession(
        sleepStart: Date,
        wakeEnd: Date,
        batteryAtSleep: Double?,
        batteryAtWake: Double?,
        wasCharging: Bool
    ) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        if let pct = batteryAtWake {
            currentBatteryLevel = pct
        }

        let (entries, rawAssertions) = await Task.detached(priority: .userInitiated) {
            let entries    = LogReader.readSleepWakeEvents(from: sleepStart, to: wakeEnd)
            let assertions = LogReader.readCurrentAssertions()
            return (entries, assertions)
        }.value

        let builder = SessionBuilder(sleepStart: sleepStart, wakeEnd: wakeEnd)
        let session = builder.build(
            sleepWakeEntries: entries,
            batteryAtSleep: batteryAtSleep,
            batteryAtWake: batteryAtWake,
            wasCharging: wasCharging,
            rawAssertions: rawAssertions
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

    // MARK: - Live state refresh

    func refreshBattery() {
        if let snap = BatteryMonitor.snapshot() {
            currentBatteryLevel = snap.percentage
            isCharging = snap.isCharging
        }
    }

    func refreshAssertions() {
        let raw = LogReader.readCurrentAssertions()
        activeAssertions = raw
            .filter { r in
                let t = r.assertionType.lowercased()
                return t.contains("preventuseridlesleep") || t.contains("preventidlesleep")
            }
            .map(\.processName)
    }

    func openReport(_ session: SleepReport) {
        selectedSession = session
    }
}
