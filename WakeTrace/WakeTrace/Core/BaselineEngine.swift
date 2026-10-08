import Foundation

// Computes rolling-median baselines from a session history.
struct BaselineEngine {
    static let windowSize = 14

    struct Baseline {
        let drainRate: Double?   // %/hr median
        let wakeRate: Double?    // wakes/hr median
        let sessionCount: Int
    }

    static func compute(from sessions: [SleepReport]) -> Baseline {
        let window = Array(sessions.prefix(windowSize))

        let drainRates = window.compactMap(\.drainRate).filter { $0 > 0 }
        let wakeRates  = window.map(\.wakeRate)

        return Baseline(
            drainRate: median(drainRates),
            wakeRate: median(wakeRates),
            sessionCount: window.count
        )
    }

    private static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[mid - 1] + sorted[mid]) / 2
            : sorted[mid]
    }
}
