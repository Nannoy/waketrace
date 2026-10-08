import Foundation

// Persists SleepReport history to disk as JSON in Application Support.
final class SessionStore {
    static let shared = SessionStore()

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appending(path: "WakeTrace", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "sessions.json")
    }()

    // MARK: - Codable shim

    private struct StoredSession: Codable {
        let id: UUID
        let sleepStart: Date
        let wakeEnd: Date
        let batteryAtSleep: Double?
        let batteryAtWake: Double?
        let wasCharging: Bool
        let wakeEvents: [StoredWakeEvent]
        let findings: [StoredFinding]
        let baselineDrainRate: Double?
        let baselineWakeRate: Double?

        struct StoredWakeEvent: Codable {
            let timestamp: Date
            let category: String
            let isDarkWake: Bool
            let rawReason: String?
        }

        struct StoredFinding: Codable {
            let category: String
            let severity: Int
            let confidence: Double
            let headline: String
            let explanation: String
            let recommendation: String?
        }
    }

    // MARK: - Load

    func load() -> [SleepReport] {
        guard let data = try? Data(contentsOf: fileURL),
              let stored = try? JSONDecoder().decode([StoredSession].self, from: data)
        else { return [] }
        return stored.compactMap(decode)
    }

    // MARK: - Save

    func save(_ reports: [SleepReport]) {
        let stored = reports.compactMap(encode)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func append(_ report: SleepReport, to existing: [SleepReport]) -> [SleepReport] {
        var updated = existing
        // Deduplicate by sleepStart proximity (within 5 minutes)
        let isDuplicate = updated.contains { abs($0.sleepStart.timeIntervalSince(report.sleepStart)) < 300 }
        if !isDuplicate { updated.insert(report, at: 0) }
        // Cap at 90 sessions
        if updated.count > 90 { updated = Array(updated.prefix(90)) }
        save(updated)
        return updated
    }

    // MARK: - Encode / Decode

    private func encode(_ r: SleepReport) -> StoredSession? {
        StoredSession(
            id: r.id,
            sleepStart: r.sleepStart,
            wakeEnd: r.wakeEnd,
            batteryAtSleep: r.batteryAtSleep,
            batteryAtWake: r.batteryAtWake,
            wasCharging: r.wasCharging,
            wakeEvents: r.wakeEvents.map {
                StoredSession.StoredWakeEvent(
                    timestamp: $0.timestamp,
                    category: $0.category.rawValue,
                    isDarkWake: $0.isDarkWake,
                    rawReason: $0.rawReason
                )
            },
            findings: r.findings.map {
                StoredSession.StoredFinding(
                    category: $0.category.rawValue,
                    severity: $0.severity.rawValue,
                    confidence: $0.confidence,
                    headline: $0.headline,
                    explanation: $0.explanation,
                    recommendation: $0.recommendation
                )
            },
            baselineDrainRate: r.baselineDrainRate,
            baselineWakeRate: r.baselineWakeRate
        )
    }

    private func decode(_ s: StoredSession) -> SleepReport? {
        let events: [WakeEventSummary] = s.wakeEvents.compactMap { e in
            guard let cat = WakeCategory(rawValue: e.category) else { return nil }
            return WakeEventSummary(timestamp: e.timestamp, category: cat, isDarkWake: e.isDarkWake, rawReason: e.rawReason)
        }
        let findings: [Finding] = s.findings.compactMap { f in
            guard let cat = FindingCategory(rawValue: f.category),
                  let sev = FindingSeverity(rawValue: f.severity)
            else { return nil }
            return Finding(category: cat, severity: sev, confidence: f.confidence, headline: f.headline, explanation: f.explanation, recommendation: f.recommendation)
        }
        return SleepReport(
            sleepStart: s.sleepStart,
            wakeEnd: s.wakeEnd,
            batteryAtSleep: s.batteryAtSleep,
            batteryAtWake: s.batteryAtWake,
            wasCharging: s.wasCharging,
            wakeEvents: events,
            findings: findings,
            baselineDrainRate: s.baselineDrainRate,
            baselineWakeRate: s.baselineWakeRate
        )
    }
}
