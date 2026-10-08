import SwiftUI

struct ReportView: View {
    let session: SleepReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.lg) {
                reportHeader
                Divider().opacity(0.4)
                BatteryCard(session: session)
                FindingsSection(findings: session.findings)
                TimelineView(session: session)
                wakeBreakdownCard
            }
            .padding(DS.xl)
        }
        .background(Color.wtBackground)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Close") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.wtLabelSec)
            }
        }
    }

    // MARK: - Header

    private var reportHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DS.xs) {
                HStack(spacing: DS.sm) {
                    StatusBadge(status: session.status)
                    Text(session.nightLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.wtLabelSec)
                }

                Text(session.duration.formattedDuration)
                    .font(.system(size: 44, weight: .ultraLight))
                    .monospacedDigit()
                    .foregroundStyle(Color.wtLabel)

                HStack(spacing: DS.md) {
                    Label(session.sleepStart.shortTime, systemImage: "moon")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.wtLabelSec)
                    Label(session.wakeEnd.shortTime, systemImage: "sun.min")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.wtLabelSec)
                }
            }

            Spacer()

            // Quick stats column
            VStack(alignment: .trailing, spacing: DS.sm) {
                quickStat(
                    label: "Wake Events",
                    value: "\(session.wakeCount)",
                    icon: "bolt"
                )
                if let rate = session.drainRate {
                    quickStat(
                        label: "Drain Rate",
                        value: String(format: "%.2f%%/hr", rate),
                        icon: "battery.75percent"
                    )
                }
                quickStat(
                    label: "Duration",
                    value: String(format: "%.1fh", session.durationHours),
                    icon: "moon.zzz"
                )
            }
        }
    }

    private func quickStat(label: String, value: String, icon: String) -> some View {
        HStack(spacing: DS.sm) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.wtLabelTert)
            Text(value)
                .monoNum(13, weight: .medium)
                .foregroundStyle(Color.wtLabelSec)
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Color.wtLabelTert)
        }
    }

    // MARK: - Wake Breakdown

    private var wakeBreakdownCard: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            Text("Wake Category Breakdown")
                .sectionHeader()

            WTCard {
                let breakdown = session.wakeCategoryBreakdown
                let total = max(1, breakdown.reduce(0) { $0 + $1.count })

                VStack(spacing: DS.md) {
                    ForEach(breakdown, id: \.category) { item in
                        HStack(spacing: DS.md) {
                            Image(systemName: item.category.systemImage)
                                .font(.system(size: 12))
                                .foregroundStyle(item.category.sparkColor)
                                .frame(width: 16)

                            Text(item.category.displayName)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.wtLabel)
                                .frame(width: 100, alignment: .leading)

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.category.sparkColor.opacity(0.25))
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(item.category.sparkColor)
                                            .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(total))
                                    }
                                    .frame(height: 6)
                            }
                            .frame(height: 6)

                            Text("\(item.count)")
                                .monoNum(12, weight: .medium)
                                .foregroundStyle(Color.wtLabelSec)
                                .frame(width: 28, alignment: .trailing)

                            Text(String(format: "%.0f%%", Double(item.count) / Double(total) * 100))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.wtLabelTert)
                                .frame(width: 32, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ReportView(session: MockData.abnormalSession)
        .frame(width: 760, height: 680)
}
