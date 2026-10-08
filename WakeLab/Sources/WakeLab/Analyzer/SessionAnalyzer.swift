import Foundation

// MARK: - SessionBuilder

struct SessionBuilder {
    let sleepStart: Date
    let wakeEnd: Date

    func build(
        sleepWakeEntries: [CompactLogEntry],
        currentBattery: BatteryState?,
        rawAssertions: [LogReader.RawAssertion]
    ) -> SleepSession {
        let batteryAtSleep = currentBattery?.percentage  // best guess for now without historical
        let batteryAtWake  = currentBattery?.percentage  // will be same at runtime; historical needs log

        let chargingAtWake = currentBattery?.isCharging

        var wakeEvents = collectWakeEvents(from: sleepWakeEntries)
        wakeEvents = deduplicate(wakeEvents, window: 3)

        let assertions = buildAssertions(from: rawAssertions)

        return SleepSession(
            sleepStartedAt: sleepStart,
            finalWakeAt: wakeEnd,
            batteryAtSleep: batteryAtSleep,
            batteryAtWake: batteryAtWake,
            wasChargingAtSleep: nil,
            wasChargingAtWake: chargingAtWake,
            wakeEvents: wakeEvents,
            assertions: assertions
        )
    }

    // MARK: - Wake event collection

    private func collectWakeEvents(from entries: [CompactLogEntry]) -> [WakeEvent] {
        entries.compactMap { entry in
            let (result, isWake) = WakeClassifier.classify(entry: entry)
            guard isWake else { return nil }
            return WakeEvent(
                timestamp: entry.timestamp,
                rawReason: entry.message,
                category: result.category,
                processName: entry.processName,
                isDarkWake: result.isDarkWake,
                confidence: result.confidence
            )
        }.sorted { $0.timestamp < $1.timestamp }
    }

    private func deduplicate(_ events: [WakeEvent], window: TimeInterval) -> [WakeEvent] {
        var result: [WakeEvent] = []
        for event in events {
            let isDuplicate = result.contains {
                abs($0.timestamp.timeIntervalSince(event.timestamp)) < window &&
                $0.category == event.category
            }
            if !isDuplicate { result.append(event) }
        }
        return result
    }

    // MARK: - Assertions

    private func buildAssertions(from raw: [LogReader.RawAssertion]) -> [PowerAssertion] {
        raw.map { r in
            PowerAssertion(
                processName: r.processName,
                pid: r.pid,
                assertionType: r.assertionType,
                reason: r.reason,
                startTime: nil,
                duration: nil
            )
        }
    }
}

// MARK: - SessionAnalyzer

struct SessionAnalyzer {
    let session: SleepSession

    func analyze() -> [Finding] {
        var findings: [Finding] = []

        if let f = analyzeBatteryDrain()   { findings.append(f) }
        if let f = analyzeWakeFrequency()  { findings.append(f) }
        findings.append(contentsOf: analyzeWakeCategories())
        if let f = analyzeAssertions()     { findings.append(f) }

        if session.durationHours < 0.5 {
            findings.append(Finding(
                category: .shortSleep,
                severity: .notice,
                confidence: 0.99,
                headline: "This was a very short sleep session.",
                explanation: String(format: "The session lasted only %.0f minutes. Stats may not be representative.",
                                    session.duration / 60),
                recommendation: nil
            ))
        }

        if findings.isEmpty {
            findings.append(Finding(
                category: .normalSession,
                severity: .normal,
                confidence: 0.9,
                headline: "Sleep session looked normal.",
                explanation: "No unusual activity was detected.",
                recommendation: nil
            ))
        }

        return findings.sorted { $0.severity > $1.severity }
    }

    // MARK: - Battery

    private func analyzeBatteryDrain() -> Finding? {
        guard let drainRate = session.batteryDrainRate,
              let delta = session.batteryDelta,
              delta > 0 else { return nil }
        if session.wasCharging { return nil }

        let (severity, headline): (Finding.Severity, String)
        switch drainRate {
        case ..<1.5:
            (severity, headline) = (.normal, "Battery drain was normal.")
        case 1.5..<2.0:
            (severity, headline) = (.notice, "Battery drain was slightly elevated.")
        case 2.0..<4.0:
            (severity, headline) = (.elevated, "Battery drain was higher than expected.")
        default:
            (severity, headline) = (.critical, "Severe battery drain while sleeping.")
        }

        let explanation = String(
            format: "Your Mac lost %.0f%% over %.1fh (%.1f%%/hr). A sleeping Mac typically drains under 1%%/hr.",
            delta, session.durationHours, drainRate
        )

        return Finding(
            category: .batteryDrain,
            severity: severity,
            confidence: 0.95,
            headline: headline,
            explanation: explanation,
            recommendation: severity >= .elevated
                ? "Review which processes or services were active during this sleep session."
                : nil
        )
    }

    // MARK: - Wake frequency

    private func analyzeWakeFrequency() -> Finding? {
        let count = session.wakeCount
        guard count > 0 else { return nil }
        let rate = session.wakeRate

        let (severity, headline): (Finding.Severity, String)
        switch rate {
        case ..<5:
            (severity, headline) = (.normal, "Wake frequency was normal.")
        case 5..<15:
            (severity, headline) = (.notice, "Your Mac woke more than usual.")
        case 15..<30:
            (severity, headline) = (.elevated, "Your Mac woke frequently while sleeping.")
        default:
            (severity, headline) = (.critical, "Your Mac woke an unusual number of times.")
        }

        let explanation = String(
            format: "%d wakes over %.1fh (%.1f/hr).",
            count, session.durationHours, rate
        )

        return Finding(
            category: .frequentWake,
            severity: severity,
            confidence: 0.88,
            headline: headline,
            explanation: explanation,
            recommendation: severity >= .elevated
                ? "Turn off Bluetooth or disable Wi-Fi before sleep to test whether the wake rate decreases."
                : nil
        )
    }

    // MARK: - Category breakdown

    private func analyzeWakeCategories() -> [Finding] {
        var results: [Finding] = []
        let total = Double(session.wakeCount)
        guard total > 0 else { return [] }

        let btCount    = session.wakeEvents(for: .bluetooth).count
        let netCount   = session.wakeEvents(for: .network).count
        let maintCount = session.wakeEvents(for: .maintenance).count

        if btCount > 3 {
            let pct = Double(btCount) / total * 100
            let sev: Finding.Severity = btCount > 20 ? .elevated : (btCount > 8 ? .notice : .normal)
            results.append(Finding(
                category: .bluetoothWake,
                severity: sev,
                confidence: 0.88,
                headline: "\(btCount) wakes were associated with Bluetooth.",
                explanation: String(format: "%.0f%% of wake events (%d of %d) were linked to Bluetooth activity.",
                                    pct, btCount, session.wakeCount),
                recommendation: sev >= .notice
                    ? "Temporarily disconnect Bluetooth accessories before sleep to test if this improves."
                    : nil
            ))
        }

        if netCount > 2 {
            let sev: Finding.Severity = netCount > 10 ? .notice : .normal
            results.append(Finding(
                category: .networkWake,
                severity: sev,
                confidence: 0.82,
                headline: "\(netCount) wakes were triggered by network activity.",
                explanation: "Background app syncing and network maintenance caused these wakes.",
                recommendation: nil
            ))
        }

        if maintCount > 0 {
            results.append(Finding(
                category: .maintenanceWake,
                severity: .normal,
                confidence: 0.90,
                headline: "\(maintCount) scheduled maintenance wakes.",
                explanation: "macOS performed Power Nap tasks and routine maintenance during sleep. This is normal.",
                recommendation: nil
            ))
        }

        return results
    }

    // MARK: - Assertions

    private func analyzeAssertions() -> Finding? {
        let blocking = session.assertions.filter(\.isPreventingSleep)
        guard !blocking.isEmpty else { return nil }

        let names = Set(blocking.map(\.processName)).joined(separator: ", ")
        let totalDuration = blocking.compactMap(\.duration).reduce(0, +)
        let durationStr = totalDuration > 0
            ? String(format: " for %.0f minutes", totalDuration / 60)
            : ""

        let sev: Finding.Severity = totalDuration > 1800 ? .elevated : .notice

        return Finding(
            category: .sleepAssertion,
            severity: sev,
            confidence: 0.92,
            headline: "\(names) held a sleep-prevention assertion.",
            explanation: "\(names) prevented your Mac from entering idle sleep\(durationStr).",
            recommendation: "Check whether \(names) needs background access during sleep."
        )
    }
}
