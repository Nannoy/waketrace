import Foundation

// MARK: - ClassificationResult

struct ClassificationResult {
    let category: WakeCategory
    let confidence: Double
    let isDarkWake: Bool
}

// MARK: - WakeClassificationRule

protocol WakeClassificationRule {
    func match(message: String, processName: String?) -> ClassificationResult?
}

// MARK: - PatternRule

struct PatternRule: WakeClassificationRule {
    let patterns: [String]
    let category: WakeCategory
    let confidence: Double
    let isDarkWakeHint: Bool  // true if this category is inherently a dark wake

    func match(message: String, processName: String?) -> ClassificationResult? {
        let lower = message.lowercased()
        guard patterns.contains(where: { lower.contains($0.lowercased()) }) else { return nil }
        let isDark = lower.contains("darkwake") || lower.contains("dark wake") || isDarkWakeHint
        return ClassificationResult(category: category, confidence: confidence, isDarkWake: isDark)
    }
}

// MARK: - WakeClassifier

struct WakeClassifier {
    // Rules evaluated in order — first match wins.
    // Updated for Apple Silicon (M-series) unified-log wake reason strings.
    static let rules: [WakeClassificationRule] = [

        // ── Lid open / user activity ──────────────────────────────────────────
        PatternRule(
            patterns: ["ec.lidopen", "lid open", "lidopen",
                       "to fullwake", "to full wake",
                       "useractivity assertion", "user activity",
                       "hid event", "keyboard", "trackpad"],
            category: .lid, confidence: 0.97, isDarkWakeHint: false),

        // ── Power / charger ──────────────────────────────────────────────────
        PatternRule(
            patterns: ["usb-c_plug", "usb-c plug", "ec.acattach", "acattach",
                       "ec.acdetach", "acdetach", "charging", "ac power", "clamshell sleep"],
            category: .power, confidence: 0.96, isDarkWakeHint: false),

        // ── Bluetooth ────────────────────────────────────────────────────────
        // Apple Silicon: "smc.sysState.Wake(0x70070000) wifibt … bluetooth-pcie/"
        // Intel: "EC.Bluetooth"
        PatternRule(
            patterns: ["bluetooth-pcie", "ec.bluetooth", "bluetooth",
                       "wifibt smc.outboxnotempty"],
            category: .bluetooth, confidence: 0.94, isDarkWakeHint: true),

        // ── Network ──────────────────────────────────────────────────────────
        PatternRule(
            patterns: ["ec.network", "ec.en", "mdnsresponder", "network maintenance", "bonjour",
                       "wifift", "wifibt"],  // wifibt without bluetooth-pcie context
            category: .network, confidence: 0.88, isDarkWakeHint: true),

        // ── SleepService / Power Nap ─────────────────────────────────────────
        // Apple Silicon: "rtc/SleepService", "Sleep Service Back to Sleep"
        PatternRule(
            patterns: ["rtc/sleepservice", "sleepservice", "sleep service",
                       "rtc/power nap", "powernap"],
            category: .maintenance, confidence: 0.93, isDarkWakeHint: true),

        // ── Scheduled maintenance / RTC ───────────────────────────────────────
        // Apple Silicon: "rtc/Maintenance", "nub-spmi0.0x02 rtc/Maintenance"
        PatternRule(
            patterns: ["rtc/maintenance", "maintenance sleep", "nub.spmiir", "rtcalarm",
                       "rtc", "maintenance"],
            category: .maintenance, confidence: 0.90, isDarkWakeHint: true),

        // ── Timer ────────────────────────────────────────────────────────────
        PatternRule(
            patterns: ["alarm", "timer", "scheduled"],
            category: .timer, confidence: 0.85, isDarkWakeHint: true),

        // ── Notification (could be app-triggered) ────────────────────────────
        PatternRule(
            patterns: ["due to notification", "notificationcenter"],
            category: .application, confidence: 0.70, isDarkWakeHint: false),
    ]

    static let systemProcesses: Set<String> = [
        "powerd", "kernel_task", "kernel", "hidd",
        "WindowServer", "loginwindow", "notifyd"
    ]

    static func classify(message: String, processName: String? = nil) -> ClassificationResult {
        for rule in rules {
            if let result = rule.match(message: message, processName: processName) {
                return result
            }
        }

        // Application heuristic
        if let proc = processName,
           !proc.isEmpty,
           !systemProcesses.contains(proc),
           !proc.hasPrefix("com.apple") {
            let isDark = message.lowercased().contains("darkwake") ||
                         message.lowercased().contains("dark wake")
            return ClassificationResult(category: .application, confidence: 0.65, isDarkWake: isDark)
        }

        let isDark = message.lowercased().contains("darkwake") ||
                     message.lowercased().contains("dark wake")
        return ClassificationResult(category: .unknown, confidence: 0.40, isDarkWake: isDark)
    }

    /// Classify a compact log entry and indicate whether it represents a wake event.
    static func classify(entry: CompactLogEntry) -> (result: ClassificationResult, isWakeEvent: Bool) {
        let msg   = entry.message.lowercased()
        let isWake = msg.contains("darkwake") || msg.contains("fullwake") ||
                     msg.contains("dark wake") || msg.contains("full wake") ||
                     msg.contains("to fullwake") || msg.contains("deep idle")
        guard isWake else {
            return (ClassificationResult(category: .unknown, confidence: 0, isDarkWake: false), false)
        }
        return (classify(message: entry.message, processName: entry.processName), true)
    }

    /// Returns true if this log entry is a user-visible (full) wake.
    static func isFullWake(entry: CompactLogEntry) -> Bool {
        LogReader.isFullWakeEvent(entry.message)
    }

    /// Returns true if this entry is a user-initiated sleep (lid close, idle, etc.).
    static func isUserSleep(entry: CompactLogEntry) -> Bool {
        LogReader.isUserSleepEvent(entry.message)
    }
}
