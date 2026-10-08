import Foundation
import IOKit.ps

struct BatteryState {
    let percentage: Double
    let isCharging: Bool
    let isOnBattery: Bool
    let currentCapacity: Int?
    let maxCapacity: Int?
}

struct BatteryReader {
    static func currentState() -> BatteryState? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        guard let list = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return nil }

        for source in list {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any] else { continue }
            guard (info[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType else { continue }

            let current = info[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max     = info[kIOPSMaxCapacityKey] as? Int ?? 100
            let pct     = Double(current) / Double(Swift.max(max, 1)) * 100.0
            let charging = (info[kIOPSIsChargingKey] as? Bool) ?? false
            let src      = info[kIOPSPowerSourceStateKey] as? String ?? ""

            return BatteryState(
                percentage: pct,
                isCharging: charging,
                isOnBattery: src == kIOPSBatteryPowerValue,
                currentCapacity: current,
                maxCapacity: max
            )
        }
        return nil
    }

    // Parse battery percentage from a pmset log line such as:
    //   "Battery charge: 82.0%"  or  "battery: charge 64%;"
    static func parseBatteryLine(_ line: String) -> Double? {
        let lower = line.lowercased()
        guard lower.contains("battery") && (lower.contains("charge") || lower.contains("%")) else { return nil }

        // Patterns: "82%", "82.0%", "charge 82%"
        let pattern = #"(\d+(?:\.\d+)?)\s*%"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let range = Range(match.range(at: 1), in: line) else { return nil }
        return Double(line[range])
    }
}
