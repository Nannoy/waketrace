import SwiftUI

struct BatteryCard: View {
    let session: SleepReport

    var body: some View {
        WTCard {
            VStack(alignment: .leading, spacing: DS.md) {
                Text("Battery")
                    .sectionHeader()

                if let before = session.batteryAtSleep, let after = session.batteryAtWake {
                    HStack(alignment: .bottom, spacing: DS.lg) {
                        // Before / After readout
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(before))")
                                    .font(.system(size: 36, weight: .light))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.wtLabel)
                                Text("%")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.wtLabelSec)
                            }
                            Text("at sleep")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.wtLabelTert)
                        }

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color.wtLabelTert)
                            .padding(.bottom, 14)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(after))")
                                    .font(.system(size: 36, weight: .light))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.wtLabel)
                                Text("%")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.wtLabelSec)
                            }
                            Text("at wake")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.wtLabelTert)
                        }

                        Spacer()

                        // Drain + rate
                        if let delta = session.batteryDelta, let rate = session.drainRate {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("−\(Int(delta))%")
                                    .font(.system(size: 22, weight: .medium))
                                    .monospacedDigit()
                                    .foregroundStyle(severityColor(for: rate))

                                HStack(spacing: 4) {
                                    Text(String(format: "%.2f%%/hr", rate))
                                        .monoNum(12)
                                        .foregroundStyle(Color.wtLabelSec)
                                    if let mult = session.drainMultiplier, mult > 1.1 {
                                        DrainMultiplierText(multiplier: mult)
                                    }
                                }

                                if let baseline = session.baselineDrainRate {
                                    Text(String(format: "Baseline %.2f%%/hr", baseline))
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.wtLabelTert)
                                }
                            }
                        }
                    }

                    batteryBar(before: before, after: after)
                } else if session.wasCharging {
                    Label("Plugged in during sleep", systemImage: "bolt.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.wtLabelSec)
                } else {
                    Text("Battery data unavailable")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.wtLabelTert)
                }
            }
        }
    }

    private func batteryBar(before: Double, after: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.wtBorder.opacity(0.4))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(severityColor(for: session.drainRate ?? 0))
                    .frame(width: max(4, geo.size.width * (after / 100)), height: 6)
            }
        }
        .frame(height: 6)
    }

    private func severityColor(for rate: Double) -> Color {
        switch rate {
        case ..<1.5: return .statusNormal
        case 1.5..<2.5: return .statusNotice
        case 2.5..<4: return .statusElevated
        default: return .statusCritical
        }
    }
}
