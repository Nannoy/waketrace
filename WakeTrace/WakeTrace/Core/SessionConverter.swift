import Foundation

// Converts the internal SleepSession (data layer) to SleepReport (UI layer).
extension SleepSession {
    func toReport(
        findings: [Finding],
        baselineDrainRate: Double? = nil,
        baselineWakeRate: Double? = nil
    ) -> SleepReport {
        let summaries: [WakeEventSummary] = wakeEvents.map { event in
            WakeEventSummary(
                timestamp: event.timestamp,
                category: event.category,
                isDarkWake: event.isDarkWake,
                rawReason: event.rawReason
            )
        }

        return SleepReport(
            sleepStart: sleepStartedAt,
            wakeEnd: finalWakeAt,
            batteryAtSleep: batteryAtSleep,
            batteryAtWake: batteryAtWake,
            wasCharging: wasCharging,
            wakeEvents: summaries,
            findings: findings,
            baselineDrainRate: baselineDrainRate,
            baselineWakeRate: baselineWakeRate
        )
    }
}
