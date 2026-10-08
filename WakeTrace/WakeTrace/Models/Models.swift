import Foundation
import SwiftUI

// MARK: - SessionStatus

enum SessionStatus: String {
    case normal, interesting, abnormal, severe, insufficientData

    var label: String {
        switch self {
        case .normal:          return "Normal"
        case .interesting:     return "Interesting"
        case .abnormal:        return "Abnormal"
        case .severe:          return "Severe"
        case .insufficientData: return "No Data"
        }
    }

    var color: Color {
        switch self {
        case .normal:          return .statusNormal
        case .interesting:     return .statusNotice
        case .abnormal:        return .statusElevated
        case .severe:          return .statusCritical
        case .insufficientData: return .secondary
        }
    }
}

// MARK: - FindingSeverity

enum FindingSeverity: Int, Comparable {
    case normal = 0, notice = 1, elevated = 2, critical = 3

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .normal:   return "Normal"
        case .notice:   return "Notice"
        case .elevated: return "Elevated"
        case .critical: return "Critical"
        }
    }

    var color: Color {
        switch self {
        case .normal:   return .statusNormal
        case .notice:   return .statusNotice
        case .elevated: return .statusElevated
        case .critical: return .statusCritical
        }
    }
}

// MARK: - WakeCategory

enum WakeCategory: String, CaseIterable, Hashable {
    case bluetooth, network, maintenance, timer, lid, user, power, application, unknown

    var displayName: String {
        switch self {
        case .bluetooth:   return "Bluetooth"
        case .network:     return "Network"
        case .maintenance: return "Maintenance"
        case .timer:       return "Timer"
        case .lid:         return "Lid Open"
        case .user:        return "User Activity"
        case .power:       return "Power Change"
        case .application: return "Application"
        case .unknown:     return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .bluetooth:   return "antenna.radiowaves.left.and.right"
        case .network:     return "wifi"
        case .maintenance: return "gearshape"
        case .timer:       return "timer"
        case .lid:         return "macbook"
        case .user:        return "cursorarrow"
        case .power:       return "bolt"
        case .application: return "app.badge"
        case .unknown:     return "questionmark.circle"
        }
    }
}

// MARK: - Finding

struct Finding: Identifiable {
    let id = UUID()
    let category: FindingCategory
    let severity: FindingSeverity
    let confidence: Double
    let headline: String
    let explanation: String
    let recommendation: String?

    var confidenceLabel: String {
        switch confidence {
        case 0.9...: return "confirmed"
        case 0.7..<0.9: return "likely"
        case 0.4..<0.7: return "possible"
        default: return "uncertain"
        }
    }
}

enum FindingCategory: String {
    case batteryDrain, frequentWake, bluetoothWake, networkWake
    case maintenanceWake, sleepAssertion, applicationActivity
    case shortSleep, normalSession
}

// MARK: - WakeEventSummary

struct WakeEventSummary: Identifiable {
    let id = UUID()
    let timestamp: Date
    let category: WakeCategory
    let isDarkWake: Bool
    var rawReason: String? = nil
}

// MARK: - SleepReport

struct SleepReport: Identifiable {
    let id = UUID()
    let sleepStart: Date
    let wakeEnd: Date
    let batteryAtSleep: Double?
    let batteryAtWake: Double?
    let wasCharging: Bool
    let wakeEvents: [WakeEventSummary]
    let findings: [Finding]
    let baselineDrainRate: Double?   // %/hour, rolling median
    let baselineWakeRate: Double?    // wakes/hour, rolling median

    var duration: TimeInterval { wakeEnd.timeIntervalSince(sleepStart) }
    var durationHours: Double  { duration / 3600 }

    var batteryDelta: Double? {
        guard let b = batteryAtSleep, let a = batteryAtWake, b != a else { return nil }
        return b - a
    }

    var drainRate: Double? {
        guard let d = batteryDelta, !wasCharging, durationHours > 0 else { return nil }
        return d / durationHours
    }

    var wakeCount: Int    { wakeEvents.count }
    var wakeRate: Double  { durationHours > 0 ? Double(wakeCount) / durationHours : 0 }

    var wakeCategoryBreakdown: [(category: WakeCategory, count: Int)] {
        var map: [WakeCategory: Int] = [:]
        wakeEvents.forEach { map[$0.category, default: 0] += 1 }
        return map.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }
    }

    var status: SessionStatus {
        let worst = findings.map(\.severity).max() ?? .normal
        switch worst {
        case .normal:   return .normal
        case .notice:   return .interesting
        case .elevated: return .abnormal
        case .critical: return .severe
        }
    }

    // Relative label for the session — "Last Sleep", "Yesterday", "Mon, Oct 6", etc.
    var relativeLabel: String {
        let cal = Calendar.current
        let now = Date()
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: wakeEnd), to: cal.startOfDay(for: now)).day ?? 0
        switch days {
        case 0:  return "Last Sleep"
        case 1:  return "Yesterday"
        case 2:  return "2 days ago"
        default:
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE, MMM d"
            return fmt.string(from: sleepStart)
        }
    }

    var shortDateLabel: String {
        let cal = Calendar.current
        let now = Date()
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: wakeEnd), to: cal.startOfDay(for: now)).day ?? 0
        switch days {
        case 0:  return "Today"
        case 1:  return "Yesterday"
        default:
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE, MMM d"
            return fmt.string(from: wakeEnd)
        }
    }

    var drainMultiplier: Double? {
        guard let rate = drainRate, let baseline = baselineDrainRate, baseline > 0 else { return nil }
        return rate / baseline
    }
}
