import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var selectedId: UUID?

    // Group sessions by week label
    private var grouped: [(week: String, sessions: [SleepReport])] {
        var map: [String: [SleepReport]] = [:]
        let cal = Calendar.current
        for session in appState.sessions {
            let key = weekLabel(for: session.wakeEnd, cal: cal)
            map[key, default: []].append(session)
        }
        return map
            .map { (week: $0.key, sessions: $0.value.sorted { $0.sleepStart > $1.sleepStart }) }
            .sorted { a, b in
                guard let da = a.sessions.first, let db = b.sessions.first else { return false }
                return da.sleepStart > db.sleepStart
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            historyHeader
            Divider().opacity(0.4)

            if appState.sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.xl) {
                        ForEach(grouped, id: \.week) { group in
                            weekSection(group)
                        }
                    }
                    .padding(DS.xl)
                }
            }
        }
        .background(Color.wtBackground)
        .frame(minWidth: 520, minHeight: 420)
    }

    // MARK: - Header

    private var historyHeader: some View {
        HStack(spacing: DS.sm) {
            Image(systemName: "clock")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.wtLabelSec)
            Text("History")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.wtLabel)
            Spacer()
            Text("\(appState.sessions.count) sessions")
                .font(.system(size: 11))
                .foregroundStyle(Color.wtLabelTert)
        }
        .padding(.horizontal, DS.xl)
        .padding(.vertical, DS.md)
    }

    // MARK: - Week section

    private func weekSection(_ group: (week: String, sessions: [SleepReport])) -> some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            Text(group.week)
                .sectionHeader()

            VStack(spacing: DS.xs) {
                ForEach(group.sessions) { session in
                    sessionRow(session)
                }
            }
        }
    }

    // MARK: - Session row

    private func sessionRow(_ session: SleepReport) -> some View {
        Button {
            appState.selectedSession = session
            openWindow(id: "report")
        } label: {
            HStack(spacing: DS.md) {
                // Date + status indicator
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.shortDateLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.wtLabel)
                    Text("\(session.sleepStart.shortTimeNoAmPm) – \(session.wakeEnd.shortTime)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.wtLabelSec)
                }
                .frame(width: 120, alignment: .leading)

                // Duration
                Text(session.duration.formattedDuration)
                    .monoNum(13)
                    .foregroundStyle(Color.wtLabelSec)
                    .frame(width: 56)

                // Battery
                if let before = session.batteryAtSleep, let after = session.batteryAtWake {
                    HStack(spacing: 3) {
                        Text("–\(Int(before - after))%")
                            .monoNum(12, weight: .medium)
                            .foregroundStyle(Color.wtLabelSec)
                    }
                    .frame(width: 44, alignment: .trailing)
                } else {
                    Spacer().frame(width: 44)
                }

                // Wake count
                HStack(spacing: 3) {
                    Image(systemName: "bolt")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.wtLabelTert)
                    Text("\(session.wakeCount)")
                        .monoNum(12)
                        .foregroundStyle(Color.wtLabelSec)
                }
                .frame(width: 36, alignment: .trailing)

                Spacer()

                StatusBadge(status: session.status)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.wtLabelTert)
            }
            .padding(.horizontal, DS.md)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedId == session.id
                          ? Color.accentColor.opacity(0.06)
                          : Color.wtSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.wtBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { selectedId = session.id } else { selectedId = nil }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: DS.md) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(Color.wtLabelTert)
            Text("No history yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.wtLabel)
            Text("WakeTrace will record sessions as you sleep.")
                .font(.system(size: 12))
                .foregroundStyle(Color.wtLabelSec)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func weekLabel(for date: Date, cal: Calendar) -> String {
        if cal.isDateInThisWeek(date) { return "This Week" }
        let last = cal.date(byAdding: .weekOfYear, value: -1, to: Date())!
        if cal.isDate(date, equalTo: last, toGranularity: .weekOfYear) { return "Last Week" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        return "Week of \(fmt.string(from: start))"
    }
}

extension Calendar {
    func isDateInThisWeek(_ date: Date) -> Bool {
        isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
        .frame(width: 600, height: 520)
}
