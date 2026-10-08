import SwiftUI

struct BatteryCard: View {
    let session: SleepReport
    @State private var progress: Double = 0

    private var drainColor: Color {
        guard let r = session.drainRate else { return Color(red: 0.18, green: 0.84, blue: 0.58) }
        switch r {
        case ..<1.5:  return Color(red: 0.18, green: 0.84, blue: 0.58)
        case 1.5..<2.5: return .statusNotice
        case 2.5..<4:   return .statusElevated
        default:        return .statusCritical
        }
    }

    var body: some View {
        WTCard {
            VStack(alignment: .leading, spacing: DS.md) {
                Text("Battery")
                    .sectionHeader()

                if let before = session.batteryAtSleep, let after = session.batteryAtWake {
                    HStack(alignment: .center, spacing: DS.xl) {
                        arcChart(before: before, after: after)
                        batteryStats(before: before, after: after)
                        Spacer()
                    }
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
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) { progress = 1.0 }
        }
    }

    // MARK: - Arc chart

    private func arcChart(before: Double, after: Double) -> some View {
        let span: Double = 0.75
        let wakeEnd  = span * (after  / 100.0) * progress
        let sleepEnd = span * (before / 100.0) * progress
        let drain = before - after

        return ZStack {
            // Track
            Circle()
                .trim(from: 0, to: span)
                .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 11, lineCap: .butt))
                .rotationEffect(.degrees(135))

            // Remaining battery
            Circle()
                .trim(from: 0, to: max(0, wakeEnd))
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.72, blue: 0.50), Color(red: 0.18, green: 0.84, blue: 0.58)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 11, lineCap: .butt)
                )
                .rotationEffect(.degrees(135))

            // Drain segment
            if before > after + 0.5 {
                Circle()
                    .trim(from: max(0, wakeEnd), to: max(0, sleepEnd))
                    .stroke(
                        LinearGradient(
                            colors: [drainColor.opacity(0.7), drainColor],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 11, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(135))
                    .shadow(color: drainColor.opacity(0.4), radius: 4)
            }

            // Center label
            VStack(spacing: 1) {
                if drain > 0.5 {
                    Text("−\(Int(drain))%")
                        .font(.system(size: 18, weight: .light, design: .monospaced))
                        .foregroundStyle(drainColor)
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.statusNotice)
                }
                Text(drain > 0.5 ? "DRAIN" : "STABLE")
                    .font(.system(size: 7, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.wtLabelTert)
            }
        }
        .frame(width: 112, height: 112)
    }

    // MARK: - Stats

    private func batteryStats(before: Double, after: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            batteryStatRow(label: "AT SLEEP", value: "\(Int(before))%", color: .wtLabelSec)
            batteryStatRow(label: "AT WAKE",  value: "\(Int(after))%",  color: .wtLabelSec)

            if let rate = session.drainRate {
                Divider().opacity(0.35).frame(width: 110)
                batteryStatRow(
                    label: "DRAIN/HR",
                    value: String(format: "%.2f%%", rate),
                    color: drainColor
                )
            }

            if let baseline = session.baselineDrainRate {
                batteryStatRow(
                    label: "BASELINE",
                    value: String(format: "%.2f%%", baseline),
                    color: .wtLabelTert
                )
            }

            if let mult = session.drainMultiplier, mult > 1.1 {
                DrainMultiplierText(multiplier: mult)
                    .padding(.top, 2)
            }
        }
    }

    private func batteryStatRow(label: String, value: String, color: Color) -> some View {
        HStack(spacing: DS.sm) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.7)
                .foregroundStyle(Color.wtLabelTert)
                .frame(width: 62, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}

#Preview("Abnormal drain") {
    BatteryCard(session: MockData.previewSession)
        .frame(width: 480)
        .padding()
}

#Preview("Normal") {
    BatteryCard(session: MockData.previewHistory.dropFirst().first ?? MockData.previewSession)
        .frame(width: 480)
        .padding()
}
