import Foundation
import IOKit.ps

// Reads instantaneous battery state via IOKit.
// Call snapshot() at sleep onset and at wake to get before/after percentages.
struct BatterySnapshot {
    let percentage: Double   // 0–100
    let isCharging: Bool
    let isOnBattery: Bool
}

enum BatteryMonitor {
    static func snapshot() -> BatterySnapshot? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
              let source = list.first,
              let desc = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any]
        else { return nil }

        let capacity    = desc[kIOPSCurrentCapacityKey] as? Double ?? 0
        let maxCapacity = desc[kIOPSMaxCapacityKey]     as? Double ?? 100
        let percentage  = maxCapacity > 0 ? (capacity / maxCapacity) * 100 : capacity

        let isCharging   = (desc[kIOPSIsChargingKey]      as? Bool) ?? false
        let powerSource  = desc[kIOPSPowerSourceStateKey]  as? String ?? ""
        let isOnBattery  = powerSource == kIOPSBatteryPowerValue

        return BatterySnapshot(
            percentage: percentage.rounded(),
            isCharging: isCharging,
            isOnBattery: isOnBattery
        )
    }
}
