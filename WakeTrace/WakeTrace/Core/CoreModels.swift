import Foundation

// Internal data-layer types used by LogReader, WakeClassifier, and SessionAnalyzer.
// These are separate from the UI-layer types in Models.swift.

// MARK: - WakeEvent (richer than WakeEventSummary; used internally by SessionBuilder)

struct WakeEvent {
    let id: UUID
    let timestamp: Date
    let rawReason: String?
    let category: WakeCategory
    let processName: String?
    let isDarkWake: Bool
    let confidence: Double

    init(
        timestamp: Date,
        rawReason: String?,
        category: WakeCategory,
        processName: String? = nil,
        isDarkWake: Bool,
        confidence: Double
    ) {
        self.id          = UUID()
        self.timestamp   = timestamp
        self.rawReason   = rawReason
        self.category    = category
        self.processName = processName
        self.isDarkWake  = isDarkWake
        self.confidence  = confidence
    }
}

// MARK: - PowerAssertion

struct PowerAssertion {
    let processName: String
    let pid: Int?
    let assertionType: String
    let reason: String?
    let startTime: Date?
    let duration: TimeInterval?

    var isPreventingSleep: Bool {
        let t = assertionType.lowercased()
        return t.contains("preventuseridlesleep") ||
               t.contains("preventidlesleep") ||
               t.contains("preventuseractivesleep")
    }
}

// MARK: - SleepSession (internal model built by SessionBuilder)

struct SleepSession {
    let sleepStartedAt: Date
    let finalWakeAt: Date

    let batteryAtSleep: Double?
    let batteryAtWake: Double?
    let wasChargingAtSleep: Bool?
    let wasChargingAtWake: Bool?

    let wakeEvents: [WakeEvent]
    let assertions: [PowerAssertion]
    var findings: [Finding]

    init(
        sleepStartedAt: Date,
        finalWakeAt: Date,
        batteryAtSleep: Double?,
        batteryAtWake: Double?,
        wasChargingAtSleep: Bool?,
        wasChargingAtWake: Bool?,
        wakeEvents: [WakeEvent],
        assertions: [PowerAssertion],
        findings: [Finding] = []
    ) {
        self.sleepStartedAt    = sleepStartedAt
        self.finalWakeAt       = finalWakeAt
        self.batteryAtSleep    = batteryAtSleep
        self.batteryAtWake     = batteryAtWake
        self.wasChargingAtSleep = wasChargingAtSleep
        self.wasChargingAtWake  = wasChargingAtWake
        self.wakeEvents        = wakeEvents
        self.assertions        = assertions
        self.findings          = findings
    }

    var duration: TimeInterval { finalWakeAt.timeIntervalSince(sleepStartedAt) }
    var durationHours: Double  { duration / 3600 }

    var batteryDelta: Double? {
        guard let before = batteryAtSleep, let after = batteryAtWake else { return nil }
        return before - after
    }

    var batteryDrainRate: Double? {
        guard let delta = batteryDelta, durationHours > 0 else { return nil }
        return delta / durationHours
    }

    var wakeCount: Int   { wakeEvents.count }
    var wakeRate: Double { durationHours > 0 ? Double(wakeCount) / durationHours : 0 }

    var wasCharging: Bool { wasChargingAtSleep == true || wasChargingAtWake == true }

    func wakeEvents(for cat: WakeCategory) -> [WakeEvent] {
        wakeEvents.filter { $0.category == cat }
    }
}
