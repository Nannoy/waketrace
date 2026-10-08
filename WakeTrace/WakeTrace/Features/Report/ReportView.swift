import SwiftUI

struct ReportView: View {
    let session: SleepReport
    @State private var statsVisible = false
    @State private var barsVisible  = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.lg) {
                reportHeader
                WTDivider()
                statsRow
                WTDivider()
                BatteryCard(session: session)
                FindingsSection(findings: session.findings)
                TimelineView(session: session)
                categoryBreakdown
            }
            .padding(DS.xl)
        }
        .background(Color.wtBackground)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.45)) { statsVisible = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.45)) { barsVisible = true }
            }
        }
    }

    // MARK: - Header

    private var reportHeader: some View {
        HStack(alignment: .center, spacing: DS.lg) {
            let ring = SleepScoreRing(session: session)
            VStack(spacing: 4) {
                ring
                Text(ring.scoreLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(ring.scoreColor)
                    .multilineTextAlignment(.center)
                    .frame(width: 88)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: DS.sm) {
                    StatusBadge(status: session.status)
                    Text(session.relativeLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.wtLabelSec)
                }

                Text(session.duration.formattedDuration)
                    .font(.system(size: 46, weight: .ultraLight))
                    .monospacedDigit()
                    .foregroundStyle(Color.wtLabel)

                HStack(spacing: DS.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.wtLabelTert)
                        Text(session.sleepStart.shortTime)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.wtLabelSec)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.to.line")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.wtLabelTert)
                        Text(session.wakeEnd.shortTime)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.wtLabelSec)
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                value: "\(session.wakeCount)",
                label: session.wakeCount == 1 ? "INTERRUPTION" : "INTERRUPTIONS",
                delay: 0.00
            )
            statDivider
            statCell(
                value: session.drainRate.map { String(format: "%.1f%%/hr", $0) } ?? "—",
                label: "DRAIN RATE",
                delay: 0.05
            )
            statDivider
            statCell(
                value: String(format: "%.1fh", session.durationHours),
                label: "TIME ASLEEP",
                delay: 0.10
            )
            statDivider
            statCell(
                value: session.wasCharging
                    ? "Charging"
                    : (session.batteryDelta.map { "−\(Int($0))%" } ?? "—"),
                label: "BATTERY USED",
                delay: 0.15
            )
        }
        .padding(.vertical, 6)
    }

    private func statCell(value: String, label: String, delay: Double) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .light, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Color.wtLabel)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .opacity(statsVisible ? 1 : 0)
                .offset(y: statsVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(delay), value: statsVisible)

            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.wtLabelTert)
                .opacity(statsVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(delay + 0.05), value: statsVisible)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.wtBorder)
            .frame(width: 0.5, height: 40)
    }

    // MARK: - Category breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            Text("Wake Category Breakdown")
                .sectionHeader()

            WTCard {
                let breakdown = session.wakeCategoryBreakdown
                let total = max(1, breakdown.reduce(0) { $0 + $1.count })

                if breakdown.isEmpty {
                    HStack(spacing: DS.sm) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.wtLabelTert)
                        Text("No wake events during this session.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.wtLabelTert)
                    }
                } else {
                    VStack(spacing: DS.md) {
                        ForEach(Array(breakdown.enumerated()), id: \.element.category) { idx, item in
                            categoryBar(item: item, total: total, index: idx)
                        }
                    }
                }
            }
        }
    }

    private func categoryBar(
        item: (category: WakeCategory, count: Int),
        total: Int,
        index: Int
    ) -> some View {
        let fraction = Double(item.count) / Double(total)

        return HStack(spacing: DS.md) {
            Image(systemName: item.category.systemImage)
                .font(.system(size: 11))
                .foregroundStyle(item.category.sparkColor)
                .frame(width: 14)

            Text(item.category.displayName)
                .font(.system(size: 12))
                .foregroundStyle(Color.wtLabel)
                .frame(width: 94, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(item.category.sparkColor.opacity(0.08))
                        .frame(height: 5)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    item.category.sparkColor.opacity(0.55),
                                    item.category.sparkColor
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * (barsVisible ? fraction : 0),
                            height: 5
                        )
                        .animation(
                            .easeOut(duration: 0.65).delay(Double(index) * 0.07 + 0.15),
                            value: barsVisible
                        )
                }
            }
            .frame(height: 5)

            Text("\(item.count)")
                .monoNum(11, weight: .medium)
                .foregroundStyle(Color.wtLabelSec)
                .frame(width: 24, alignment: .trailing)

            Text(String(format: "%.0f%%", fraction * 100))
                .font(.system(size: 10))
                .foregroundStyle(Color.wtLabelTert)
                .frame(width: 30, alignment: .trailing)
        }
        .opacity(barsVisible ? 1 : 0)
        .offset(x: barsVisible ? 0 : -14)
        .animation(
            .easeOut(duration: 0.35).delay(Double(index) * 0.05),
            value: barsVisible
        )
    }
}

#Preview {
    ReportView(session: MockData.previewSession)
        .frame(width: 760, height: 680)
}
