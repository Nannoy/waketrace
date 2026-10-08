import Foundation

enum MockData {

    // MARK: - Abnormal session (showcase session)

    static let abnormalSession: SleepReport = {
        let cal = Calendar.current
        let today = Date()
        let sleepStart = cal.date(bySettingHour: 0, minute: 14, second: 0, of: today)!
        let wakeEnd    = cal.date(bySettingHour: 8, minute: 3, second: 0, of: today)!

        let events = makeBluetoothHeavyEvents(from: sleepStart, to: wakeEnd)

        return SleepReport(
            sleepStart: sleepStart,
            wakeEnd: wakeEnd,
            batteryAtSleep: 83,
            batteryAtWake: 61,
            wasCharging: false,
            wakeEvents: events,
            findings: [
                Finding(
                    category: .batteryDrain,
                    severity: .critical,
                    confidence: 0.95,
                    headline: "Severe battery drain while sleeping.",
                    explanation: "Your Mac lost 22% over 7h 49m (2.8%/hr). A sleeping Mac typically drains under 1%/hr.",
                    recommendation: nil
                ),
                Finding(
                    category: .bluetoothWake,
                    severity: .elevated,
                    confidence: 0.91,
                    headline: "Bluetooth woke your Mac 63 times.",
                    explanation: "63 of 94 wake events (67%) were linked to Bluetooth activity. Your recent average is 4 per night.",
                    recommendation: "Disconnect Bluetooth accessories before sleep tonight to see whether drain improves."
                ),
                Finding(
                    category: .maintenanceWake,
                    severity: .normal,
                    confidence: 0.92,
                    headline: "17 maintenance wakes were detected.",
                    explanation: "macOS performed Power Nap tasks and scheduled maintenance. This is normal.",
                    recommendation: nil
                )
            ],
            baselineDrainRate: 0.48,
            baselineWakeRate: 3.2
        )
    }()

    // MARK: - Normal session

    static let normalSession: SleepReport = {
        let cal = Calendar.current
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let sleepStart = cal.date(bySettingHour: 23, minute: 18, second: 0, of: yesterday)!
        let wakeEnd    = cal.date(bySettingHour: 7, minute: 41, second: 0, of: yesterday.addingTimeInterval(86400))!

        return SleepReport(
            sleepStart: sleepStart,
            wakeEnd: wakeEnd,
            batteryAtSleep: 91,
            batteryAtWake: 87,
            wasCharging: false,
            wakeEvents: makeNormalEvents(from: sleepStart, to: wakeEnd),
            findings: [
                Finding(
                    category: .normalSession,
                    severity: .normal,
                    confidence: 0.95,
                    headline: "Sleep session looked normal.",
                    explanation: "No unusual activity was detected. Battery drain was well within the expected range.",
                    recommendation: nil
                )
            ],
            baselineDrainRate: 0.48,
            baselineWakeRate: 3.2
        )
    }()

    // MARK: - Notice session (app preventing sleep)

    static let assertionSession: SleepReport = {
        let cal = Calendar.current
        let d = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let sleepStart = cal.date(bySettingHour: 22, minute: 53, second: 0, of: d)!
        let wakeEnd    = cal.date(bySettingHour: 7, minute: 22, second: 0, of: d.addingTimeInterval(86400))!

        return SleepReport(
            sleepStart: sleepStart,
            wakeEnd: wakeEnd,
            batteryAtSleep: 78,
            batteryAtWake: 68,
            wasCharging: false,
            wakeEvents: makeNormalEvents(from: sleepStart, to: wakeEnd),
            findings: [
                Finding(
                    category: .sleepAssertion,
                    severity: .notice,
                    confidence: 0.93,
                    headline: "WhatsApp held a sleep-prevention assertion.",
                    explanation: "WhatsApp prevented your Mac from entering idle sleep for approximately 42 minutes during this session.",
                    recommendation: "Check whether WhatsApp needs background access while your Mac is sleeping."
                ),
                Finding(
                    category: .batteryDrain,
                    severity: .notice,
                    confidence: 0.88,
                    headline: "Battery drain was slightly elevated.",
                    explanation: "Your Mac lost 10% over 8h 29m (1.2%/hr). This is mildly above your typical 0.5%/hr.",
                    recommendation: nil
                )
            ],
            baselineDrainRate: 0.48,
            baselineWakeRate: 3.2
        )
    }()

    // MARK: - History (7 sessions)

    static let history: [SleepReport] = {
        let base = Date()
        var sessions: [SleepReport] = [abnormalSession, normalSession, assertionSession]

        // Add a few more simple sessions to fill history
        for i in 3..<7 {
            let d = Calendar.current.date(byAdding: .day, value: -i, to: base)!
            let cal = Calendar.current
            let s = cal.date(bySettingHour: 23, minute: Int.random(in: 0..<30), second: 0, of: d)!
            let e = s.addingTimeInterval(Double.random(in: 25200...31200)) // 7–8.7h
            let drain = Double.random(in: 2...5)
            let drainRate = drain / (e.timeIntervalSince(s) / 3600)
            let sev: FindingSeverity = drainRate > 1.5 ? .notice : .normal

            sessions.append(SleepReport(
                sleepStart: s,
                wakeEnd: e,
                batteryAtSleep: Double.random(in: 75...95),
                batteryAtWake: Double(Int.random(in: 70...90) - Int(drain)),
                wasCharging: false,
                wakeEvents: makeNormalEvents(from: s, to: e),
                findings: [
                    Finding(
                        category: .normalSession,
                        severity: sev,
                        confidence: 0.90,
                        headline: sev == .normal ? "Sleep session looked normal." : "Slightly elevated drain.",
                        explanation: "",
                        recommendation: nil
                    )
                ],
                baselineDrainRate: 0.48,
                baselineWakeRate: 3.2
            ))
        }
        return sessions
    }()

    // MARK: - Event generators

    private static func makeBluetoothHeavyEvents(from start: Date, to end: Date) -> [WakeEventSummary] {
        var events: [WakeEventSummary] = []
        var t = start.addingTimeInterval(1380) // +23min

        // 63 Bluetooth wakes scattered through the night
        for _ in 0..<63 {
            events.append(WakeEventSummary(timestamp: t, category: .bluetooth, isDarkWake: true, rawReason: "DarkWake from Deep Idle [CDNP] : due to smc.sysState.Wake wifibt SMC.OutboxNotEmpty bluetooth-pcie/"))
            t = t.addingTimeInterval(Double.random(in: 240...720))
            if t >= end { break }
        }

        // 17 maintenance wakes
        t = start.addingTimeInterval(900)
        for _ in 0..<17 {
            events.append(WakeEventSummary(timestamp: t, category: .maintenance, isDarkWake: true, rawReason: "DarkWake from Deep Idle [CDNP] : due to NUB.SPMISw3IRQ nub-spmi0.0x02 rtc/Maintenance"))
            t = t.addingTimeInterval(Double.random(in: 1200...2400))
            if t >= end { break }
        }

        // Network wakes
        t = start.addingTimeInterval(3600)
        for _ in 0..<14 {
            events.append(WakeEventSummary(timestamp: t, category: .network, isDarkWake: true, rawReason: "DarkWake from Deep Idle [CDNP] : due to NUB.SPMISw3IRQ rtc/SleepService"))
            t = t.addingTimeInterval(Double.random(in: 900...1800))
            if t >= end { break }
        }

        // Final full wake
        events.append(WakeEventSummary(timestamp: end, category: .lid, isDarkWake: false, rawReason: "DarkWake to FullWake from Deep Idle [CDNVAP] : due to UserActivity Assertion"))

        return events.sorted { $0.timestamp < $1.timestamp }
    }

    private static func makeNormalEvents(from start: Date, to end: Date) -> [WakeEventSummary] {
        var events: [WakeEventSummary] = []
        var t = start.addingTimeInterval(3600)

        // 3–6 maintenance wakes
        for _ in 0..<Int.random(in: 3...6) {
            if t >= end { break }
            events.append(WakeEventSummary(timestamp: t, category: .maintenance, isDarkWake: true))
            t += Double.random(in: 3600...5400)
        }

        events.append(WakeEventSummary(timestamp: end, category: .lid, isDarkWake: false))
        return events.sorted { $0.timestamp < $1.timestamp }
    }
}
