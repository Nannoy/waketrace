import Foundation

// MARK: - CLI Entry Point

func run() {
    let args = ParsedArgs.parse()

    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "MMM d HH:mm"

    // ---- Determine sleep window ----
    let sleepStart: Date
    let wakeEnd: Date

    if let s = args.start, let e = args.end {
        sleepStart = s
        wakeEnd    = e
    } else if let s = args.start {
        sleepStart = s
        wakeEnd    = Date()
    } else {
        print("🔍 Looking for most recent sleep session…")
        guard let boundary = LogReader.mostRecentSleepBoundary() else {
            print("❌ Could not find a recent sleep session in the pmset log.")
            print("   Try specifying a window manually: wakeLab --start '2024-01-01 22:00:00' --end '2024-01-02 07:00:00'")
            print("")
            print("   If this is your first run, ensure WakeLab has access to system logs.")
            Darwin.exit(1)
        }
        sleepStart = boundary.sleepStart
        wakeEnd    = boundary.wakeEnd
    }

    let duration = wakeEnd.timeIntervalSince(sleepStart)
    let durationHours = duration / 3600

    let windowFormatter = DateFormatter()
    windowFormatter.locale = Locale(identifier: "en_US_POSIX")
    windowFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"

    print("")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("  WakeLab — Sleep Diagnostic")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("  Sleep:  \(windowFormatter.string(from: sleepStart))")
    print("  Wake:   \(windowFormatter.string(from: wakeEnd))")
    print(String(format: "  Duration: %.1f hours", durationHours))
    print("")

    if durationHours < 0 {
        print("❌ Invalid window: wake time is before sleep time.")
        Darwin.exit(1)
    }

    // ---- Collect data ----
    print("📡 Collecting data…")

    let currentBattery = BatteryReader.currentState()

    print("   • Querying sleep/wake events (log show)…")
    let sleepWakeEntries = LogReader.readSleepWakeEvents(from: sleepStart, to: wakeEnd)
    print("     Found \(sleepWakeEntries.count) events")

    print("   • Reading power assertions…")
    let rawAssertions = LogReader.readCurrentAssertions()
    print("     Found \(rawAssertions.count) assertions")
    print("")

    // ---- Build session ----
    let builder = SessionBuilder(sleepStart: sleepStart, wakeEnd: wakeEnd)
    let session = builder.build(
        sleepWakeEntries: sleepWakeEntries,
        currentBattery: currentBattery,
        rawAssertions: rawAssertions
    )

    // ---- Analyze ----
    let analyzer  = SessionAnalyzer(session: session)
    var analyzed  = session
    analyzed.findings = analyzer.analyze()

    // ---- Output ----
    if args.format == .json {
        printJSON(session: analyzed)
    } else {
        printReport(session: analyzed)
    }
}

// MARK: - Text Report

func printReport(session: SleepSession) {
    let shortFmt = DateFormatter()
    shortFmt.locale = Locale(identifier: "en_US_POSIX")
    shortFmt.dateFormat = "h:mm a"

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("  RESULTS")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("")

    // Battery
    print("  BATTERY")
    if let before = session.batteryAtSleep, let after = session.batteryAtWake,
       before != after {
        let delta = before - after
        let sign  = delta >= 0 ? "-" : "+"
        print(String(format: "  %.0f%% → %.0f%%  (%@%.0f%%)", before, after, sign, abs(delta)))
        if let rate = session.batteryDrainRate {
            print(String(format: "  Drain rate: %.2f%%/hour", rate))
        }
    } else {
        // Historical battery unavailable — this is expected for manually-specified windows.
        // Real-time monitoring (Phase 1) will capture battery at sleep/wake transitions.
        print("  Historical battery data unavailable for this window.")
        print("  (Real-time monitoring — Phase 1 — will capture battery at sleep/wake.)")
        if let current = BatteryReader.currentState() {
            print(String(format: "  Current battery: %.0f%%", current.percentage))
        }
    }
    if session.wasCharging == true { print("  (Device was or is charging)") }
    print("")

    // Wake events
    print("  WAKE EVENTS")
    print("  Total: \(session.wakeCount)")
    if session.wakeCount > 0 {
        // Count by category
        var byCat: [WakeCategory: Int] = [:]
        for e in session.wakeEvents { byCat[e.category, default: 0] += 1 }
        for (cat, count) in byCat.sorted(by: { $0.value > $1.value }) {
            print("  • \(cat.displayName): \(count)")
        }
    }
    print("")

    // Assertions
    if !session.assertions.isEmpty {
        print("  POWER ASSERTIONS")
        for a in session.assertions {
            var line = "  • \(a.processName): \(a.assertionType)"
            if let r = a.reason { line += " — \"\(r)\"" }
            print(line)
        }
        print("")
    }

    // Findings
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("  ASSESSMENT")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("")

    let worstSeverity = session.findings.map(\.severity).max() ?? .normal
    let statusLabel: String
    switch worstSeverity {
    case .normal:   statusLabel = "✅ NORMAL"
    case .notice:   statusLabel = "ℹ️  NOTICE"
    case .elevated: statusLabel = "⚠️  ELEVATED"
    case .critical: statusLabel = "🔴 CRITICAL"
    }
    print("  Status: \(statusLabel)")
    print("")

    for (i, finding) in session.findings.enumerated() {
        print("  \(i + 1). [\(finding.severity.label)] \(finding.headline)")
        print("     \(finding.explanation)")
        if let rec = finding.recommendation {
            print("     → \(rec)")
        }
        print("")
    }

    // Raw events dump (for debugging)
    if session.wakeCount > 0 {
        let shortTime = DateFormatter()
        shortTime.locale = Locale(identifier: "en_US_POSIX")
        shortTime.dateFormat = "HH:mm:ss"

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  WAKE EVENT TIMELINE (first 20)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        for event in session.wakeEvents.prefix(20) {
            let kind = event.isDarkWake ? "Dark" : "Full"
            let proc = event.processName.map { " [\($0)]" } ?? ""
            print("  \(shortTime.string(from: event.timestamp))  \(kind) Wake  \(event.category.displayName)\(proc)")
            if let raw = event.rawReason {
                let trimmed = raw.prefix(80)
                print("      \(trimmed)")
            }
        }
        if session.wakeCount > 20 {
            print("  … and \(session.wakeCount - 20) more events")
        }
        print("")
    }

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("  WakeLab — Phase 0 diagnostic spike")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("")
}

// MARK: - JSON Output

func printJSON(session: SleepSession) {
    let iso = ISO8601DateFormatter()

    var byCat: [String: Int] = [:]
    for e in session.wakeEvents { byCat[e.category.rawValue, default: 0] += 1 }

    var obj: [String: Any] = [
        "sleepStart":  iso.string(from: session.sleepStartedAt),
        "wakeEnd":     iso.string(from: session.finalWakeAt),
        "durationHours": round(session.durationHours * 10) / 10,
        "wakeCount":   session.wakeCount,
        "wakeReasons": byCat,
        "assertions":  session.assertions.map { ["process": $0.processName, "type": $0.assertionType] },
        "findings":    session.findings.map { [
            "severity":    $0.severity.label,
            "confidence":  $0.confidence,
            "headline":    $0.headline,
            "explanation": $0.explanation
        ]}
    ]

    if let b = session.batteryAtSleep  { obj["batteryBefore"] = b }
    if let a = session.batteryAtWake   { obj["batteryAfter"]  = a }
    if let d = session.batteryDelta    { obj["batteryLost"]   = round(d * 10) / 10 }
    if let r = session.batteryDrainRate { obj["drainRatePerHour"] = round(r * 100) / 100 }

    if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
       let str = String(data: data, encoding: .utf8) {
        print(str)
    }
}

// MARK: - Argument Parsing

struct ParsedArgs {
    let start: Date?
    let end: Date?
    let format: Format

    enum Format { case text, json }

    static func parse() -> ParsedArgs {
        var start: Date? = nil
        var end: Date?   = nil
        var fmt: Format  = .text

        let argv = Array(CommandLine.arguments.dropFirst())
        var i = 0
        while i < argv.count {
            switch argv[i] {
            case "--start", "-s":
                i += 1
                if i < argv.count { start = parseDate(argv[i]) }
            case "--end", "-e":
                i += 1
                if i < argv.count { end = parseDate(argv[i]) }
            case "--format", "-f":
                i += 1
                if i < argv.count { fmt = argv[i] == "json" ? .json : .text }
            case "--json":
                fmt = .json
            case "--help", "-h":
                printHelp()
                Darwin.exit(0)
            default:
                break
            }
            i += 1
        }
        return ParsedArgs(start: start, end: end, format: fmt)
    }

    private static func parseDate(_ str: String) -> Date? {
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
        ]
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        for fmt in formats {
            f.dateFormat = fmt
            if let d = f.date(from: str) { return d }
        }
        return ISO8601DateFormatter().date(from: str)
    }
}

func printHelp() {
    print("""
    WakeLab — WakeTrace Phase 0 diagnostic spike

    USAGE
      WakeLab [--start DATE] [--end DATE] [--format text|json]

    OPTIONS
      --start, -s   Sleep session start (default: auto-detect from pmset log)
      --end, -e     Sleep session end   (default: auto-detect from pmset log)
      --format, -f  Output format: text (default) or json
      --json        Shorthand for --format json
      --help, -h    Show this help

    DATE FORMATS
      2024-01-01 22:30:00
      2024-01-01 22:30
      2024-01-01

    EXAMPLES
      WakeLab
      WakeLab --start '2024-01-01 23:00:00' --end '2024-01-02 07:30:00'
      WakeLab --format json
    """)
}

// ---- Run ----
run()
