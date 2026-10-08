import Foundation

// MARK: - WakeCategory

enum WakeCategory: String, CaseIterable {
    case bluetooth
    case network
    case maintenance
    case timer
    case lid
    case user
    case power
    case application
    case unknown

    var displayName: String {
        switch self {
        case .bluetooth:    return "Bluetooth"
        case .network:      return "Network"
        case .maintenance:  return "Maintenance"
        case .timer:        return "Timer/Scheduled"
        case .lid:          return "Lid Open"
        case .user:         return "User Activity"
        case .power:        return "Power Change"
        case .application:  return "Application"
        case .unknown:      return "Unknown"
        }
    }
}

// MARK: - WakeEvent

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
        self.id = UUID()
        self.timestamp = timestamp
        self.rawReason = rawReason
        self.category = category
        self.processName = processName
        self.isDarkWake = isDarkWake
        self.confidence = confidence
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

// MARK: - Finding

struct Finding {
    enum Category: String {
        case batteryDrain
        case frequentWake
        case bluetoothWake
        case networkWake
        case maintenanceWake
        case sleepAssertion
        case applicationActivity
        case shortSleep
        case normalSession
    }

    enum Severity: Int, Comparable {
        case normal   = 0
        case notice   = 1
        case elevated = 2
        case critical = 3

        var label: String {
            switch self {
            case .normal:   return "NORMAL"
            case .notice:   return "NOTICE"
            case .elevated: return "ELEVATED"
            case .critical: return "CRITICAL"
            }
        }

        static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let category: Category
    let severity: Severity
    let confidence: Double
    let headline: String
    let explanation: String
    let recommendation: String?

    var confidenceLabel: String {
        switch confidence {
        case 0.9...:      return "confirmed"
        case 0.7..<0.9:   return "likely"
        case 0.4..<0.7:   return "possible"
        default:          return "uncertain"
        }
    }
}

// MARK: - SleepSession

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
        self.sleepStartedAt = sleepStartedAt
        self.finalWakeAt = finalWakeAt
        self.batteryAtSleep = batteryAtSleep
        self.batteryAtWake = batteryAtWake
        self.wasChargingAtSleep = wasChargingAtSleep
        self.wasChargingAtWake = wasChargingAtWake
        self.wakeEvents = wakeEvents
        self.assertions = assertions
        self.findings = findings
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

    var wakeCount: Int  { wakeEvents.count }
    var wakeRate: Double { durationHours > 0 ? Double(wakeCount) / durationHours : 0 }

    var wasCharging: Bool {
        wasChargingAtSleep == true || wasChargingAtWake == true
    }

    func wakeEvents(for category: WakeCategory) -> [WakeEvent] {
        wakeEvents.filter { $0.category == category }
    }
}

// MARK: - EvidenceSource

enum EvidenceSource: String {
    case pmsetLog
    case unifiedLog
    case iokit
    case batteryState
    case userProvided
}
