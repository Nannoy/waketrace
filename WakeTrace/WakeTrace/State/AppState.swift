import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var sessions: [SleepReport] = MockData.history
    @Published var selectedSession: SleepReport?
    @Published var isFirstLaunch: Bool = false
    @Published var currentBatteryLevel: Double = 78
    @Published var isCharging: Bool = false
    @Published var baselineSessionCount: Int = 7

    var lastSession: SleepReport? { sessions.first }

    var hasBaseline: Bool { baselineSessionCount >= 5 }

    var baselineDrainRate: Double? {
        guard hasBaseline else { return nil }
        return 0.48
    }

    func openReport(_ session: SleepReport) {
        selectedSession = session
    }

    func selectLastSession() {
        selectedSession = lastSession
    }
}
