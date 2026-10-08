import Foundation

// MARK: - CompactLogEntry

struct CompactLogEntry {
    let timestamp: Date
    let logType: String    // "Df", "E ", etc.
    let processName: String
    let category: String   // e.g. "sleepWake", "assertions"
    let message: String
    let rawLine: String
}

// MARK: - LogReader

struct LogReader {

    // MARK: - Log Show

    /// Query the unified log using `log show` with a tight predicate and optional hour window.
    /// Returns parsed compact-format entries. Applies a 30-second timeout.
    static func queryLog(predicate: String, lastHours: Int = 24) -> [CompactLogEntry] {
        let output = runCommand("/usr/bin/log", args: [
            "show",
            "--predicate", predicate,
            "--last", "\(lastHours)h",
            "--style", "compact",
            "--timezone", "local"
        ], timeoutSeconds: 30)

        return output
            .components(separatedBy: "\n")
            .compactMap(parseCompactLine)
    }

    /// Query the unified log for a specific date range.
    static func queryLog(predicate: String, from start: Date, to end: Date) -> [CompactLogEntry] {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let output = runCommand("/usr/bin/log", args: [
            "show",
            "--predicate", predicate,
            "--start", fmt.string(from: start),
            "--end", fmt.string(from: end),
            "--style", "compact",
            "--timezone", "local"
        ], timeoutSeconds: 30)

        return output
            .components(separatedBy: "\n")
            .compactMap(parseCompactLine)
    }

    // MARK: - Sleep/Wake Events

    static let sleepWakePredicate =
        #"process == "powerd" AND subsystem == "com.apple.powerd" AND category == "sleepWake""#

    static func readSleepWakeEvents(lastHours: Int = 24) -> [CompactLogEntry] {
        queryLog(predicate: sleepWakePredicate, lastHours: lastHours)
            .filter { isSleepWakeEvent($0.message) }
    }

    static func readSleepWakeEvents(from start: Date, to end: Date) -> [CompactLogEntry] {
        queryLog(predicate: sleepWakePredicate, from: start, to: end)
            .filter { isSleepWakeEvent($0.message) }
    }

    private static func isSleepWakeEvent(_ message: String) -> Bool {
        let lower = message.lowercased()
        // Exclude internal mode-change lines — these are state transitions that accompany real
        // wake events but are not wake events themselves.
        if lower.hasPrefix("vm.darkwake_mode") { return false }
        if lower.hasPrefix("sendonrespnotification") || lower.hasPrefix("sendnoresp") { return false }
        if lower.hasPrefix("updating wake") || lower.hasPrefix("wakedetails") { return false }
        return lower.contains("darkwake") || lower.contains("fullwake") ||
               lower.contains("dark wake") || lower.contains("full wake") ||
               lower.contains("entering sleep state") ||
               lower.contains("systemstart") || lower.contains("deep idle")
    }

    // MARK: - Sleep Boundary Detection

    struct SleepBoundary {
        let sleepStart: Date
        let wakeEnd: Date
    }

    /// Returns the most recently completed sleep session (initial sleep → final user-triggered wake).
    static func mostRecentSleepBoundary() -> SleepBoundary? {
        findSleepBoundaries().last
    }

    static func findSleepBoundaries() -> [SleepBoundary] {
        let entries = readSleepWakeEvents(lastHours: 24)
        var boundaries: [SleepBoundary] = []

        // Find user-initiated sleep events (Clamshell, User, Idle) vs maintenance sleeps
        // Find FullWake events as the end of a session
        var lastUserSleepDate: Date? = nil

        for entry in entries {
            let msg = entry.message.lowercased()

            let isUserInitiatedSleep = isUserSleepEvent(entry.message)
            let isFullWake = isFullWakeEvent(entry.message)

            if isUserInitiatedSleep && !isFullWake {
                lastUserSleepDate = entry.timestamp
            } else if isFullWake, let sleepDate = lastUserSleepDate {
                boundaries.append(SleepBoundary(sleepStart: sleepDate, wakeEnd: entry.timestamp))
                lastUserSleepDate = nil
            }

            _ = msg  // silence unused warning
        }

        return boundaries
    }

    static func isUserSleepEvent(_ message: String) -> Bool {
        let lower = message.lowercased()
        // User-initiated sleep: clamshell (lid close), idle sleep (display timer), or button
        // NOT maintenance sleep or sleep service
        guard lower.contains("entering sleep state") else { return false }
        let isMaintenance = lower.contains("maintenance") || lower.contains("sleep service") ||
                            lower.contains("back to sleep")
        return !isMaintenance
    }

    static func isFullWakeEvent(_ message: String) -> Bool {
        let lower = message.lowercased()
        // "DarkWake to FullWake" or just "FullWake"
        return lower.contains("to fullwake") || lower.contains("to full wake") ||
               lower.contains("fullwake from") || (lower.contains("full wake") && !lower.contains("dark wake"))
    }

    // MARK: - Power Assertions

    /// Reads current power assertions from `pmset -g assertions`.
    static func readCurrentAssertions() -> [RawAssertion] {
        let output = runCommand("/usr/bin/pmset", args: ["-g", "assertions"], timeoutSeconds: 5)
        return parseAssertionsOutput(output)
    }

    struct RawAssertion {
        let processName: String
        let pid: Int?
        let assertionType: String
        let reason: String?
    }

    private static func parseAssertionsOutput(_ output: String) -> [RawAssertion] {
        var results: [RawAssertion] = []

        // Actual format (from pmset -g assertions):
        //   pid 416(runningboardd): [0x00004af00001a7a6] 00:00:00 PreventUserIdleSystemSleep named: "..."
        //   pid 99719(caffeinate): [0x00004aec0001a7a4] 00:00:04 PreventUserIdleSystemSleep named: "caffeinate..."
        let pattern = #"pid\s+(\d+)\(([^)]+)\):\s+\[[^\]]+\]\s+\S+\s+(\w+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }

        for line in output.components(separatedBy: "\n") {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            guard let match = regex.firstMatch(in: line, range: range) else { continue }

            let pid       = match.range(at: 1).location != NSNotFound ? Int(nsLine.substring(with: match.range(at: 1))) : nil
            let name      = match.range(at: 2).location != NSNotFound ? nsLine.substring(with: match.range(at: 2)) : "unknown"
            let assertType = match.range(at: 3).location != NSNotFound ? nsLine.substring(with: match.range(at: 3)) : ""

            // Extract named reason: named: "..."
            var reason: String? = nil
            if let rRange = line.range(of: #"named:\s*"([^"]+)""#, options: .regularExpression),
               let inner = line.range(of: #""([^"]+)""#, options: .regularExpression, range: rRange) {
                reason = String(line[inner]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }

            results.append(RawAssertion(processName: name, pid: pid, assertionType: assertType, reason: reason))
        }
        return results
    }

    // MARK: - Battery (from IOKit and log)

    /// Query powerd for battery state changes in the log window.
    static func readBatteryEvents(from start: Date, to end: Date) -> [CompactLogEntry] {
        let predicate = #"process == "powerd" AND subsystem == "com.apple.powerd" AND (eventMessage CONTAINS[c] "battery" OR eventMessage CONTAINS[c] "charge")"#
        return queryLog(predicate: predicate, from: start, to: end)
    }

    // MARK: - Compact Format Parsing

    static func parseCompactLine(_ line: String) -> CompactLogEntry? {
        // Format: "YYYY-MM-DD HH:mm:ss.SSS Ty ProcessName[PID:TID] [subsystem:category] message"
        guard line.count > 30 else { return nil }
        if line.hasPrefix("Timestamp") { return nil }

        // Timestamp is always the first 23 chars
        let tsStr = String(line.prefix(23))
        guard let timestamp = compactDateFormatter.date(from: tsStr) else { return nil }

        // Everything after the timestamp and its trailing space
        let rest = String(line.dropFirst(24))

        // Split into: [typeCode, process[PID:TID], remainder...]
        // maxSplits: 2 so remainder stays intact
        let tokens = rest.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard tokens.count >= 3 else { return nil }

        let logType     = String(tokens[0])
        let processStr  = String(tokens[1])
        let processName = processStr.components(separatedBy: "[").first ?? processStr

        // tokens[2] should start with [subsystem:category] or just be the message
        let remainder   = String(tokens[2])
        var category    = ""
        var message     = remainder

        if remainder.hasPrefix("["),
           let closeBracketIdx = remainder.firstIndex(of: "]") {
            let tagContent = String(remainder[remainder.index(after: remainder.startIndex)..<closeBracketIdx])
            // e.g. "com.apple.powerd:sleepWake"
            category = tagContent.components(separatedBy: ":").last ?? tagContent
            let afterClose = remainder.index(after: closeBracketIdx)
            message = afterClose < remainder.endIndex
                ? String(remainder[afterClose...]).trimmingCharacters(in: .whitespaces)
                : ""
        }

        return CompactLogEntry(
            timestamp: timestamp,
            logType: logType,
            processName: processName,
            category: category,
            message: message,
            rawLine: line
        )
    }

    private static let compactDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    // MARK: - Process Runner with Timeout

    static func runCommand(_ path: String, args: [String], timeoutSeconds: Double = 30) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError  = Pipe()

        do {
            try task.run()
        } catch {
            return ""
        }

        // Kill after timeout
        let deadline = DispatchTime.now() + timeoutSeconds
        DispatchQueue.global().asyncAfter(deadline: deadline) {
            if task.isRunning { task.terminate() }
        }

        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
