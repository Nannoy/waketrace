import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var hoveredId: UUID?

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
        .frame(minWidth: 640, minHeight: 480)
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
            if appState.sessions.count >= 2 {
                let sessions = Array(appState.sessions.prefix(7))
                let avgH = sessions.map { $0.durationHours }.reduce(0, +) / Double(sessions.count)
                Text(String(format: "7-day avg  %.1fh", avgH))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelTert)
                    .padding(.trailing, DS.sm)
            }
            Text("\(appState.sessions.count) \(appState.sessions.count == 1 ? "session" : "sessions")")
                .font(.system(size: 11))
                .foregroundStyle(Color.wtLabelTert)
        }
        .padding(.horizontal, DS.xl)
        .padding(.vertical, DS.md)
    }

    // MARK: - Week section

    private func weekSection(_ group: (week: String, sessions: [SleepReport])) -> some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            HStack(alignment: .bottom, spacing: DS.md) {
                Text(group.week)
                    .sectionHeader()
                weekSparkline(group.sessions)
                Spacer()
                weekStats(group.sessions)
            }
            .padding(.bottom, 4)

            VStack(spacing: DS.xs) {
                ForEach(group.sessions) { session in
                    sessionRow(session)
                }
            }
        }
    }

    // Mini bar chart: each bar = one night, height ∝ duration, color = status
    private func weekSparkline(_ sessions: [SleepReport]) -> some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(sessions.sorted { $0.sleepStart < $1.sleepStart }) { session in
                let frac = min(session.durationHours, 10.0) / 10.0
                RoundedRectangle(cornerRadius: 2)
                    .fill(session.status.color.opacity(0.55))
                    .frame(width: 9, height: max(4, 26 * frac))
            }
        }
        .frame(height: 26, alignment: .bottom)
    }

    // Avg duration + avg drain label for the week
    private func weekStats(_ sessions: [SleepReport]) -> some View {
        let avgH = sessions.map { $0.durationHours }.reduce(0, +) / Double(sessions.count)
        let drains = sessions.compactMap { s -> Double? in
            guard let b = s.batteryAtSleep, let a = s.batteryAtWake, b > a, !s.wasCharging else { return nil }
            return b - a
        }

        return HStack(spacing: DS.md) {
            Label(String(format: "%.1fh avg", avgH), systemImage: "moon.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.wtLabelTert)
            if let avg = drains.isEmpty ? nil : drains.reduce(0, +) / Double(drains.count) {
                Label(String(format: "−%.0f%% avg drain", avg), systemImage: "battery.50percent")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.wtLabelTert)
            }
        }
    }

    // MARK: - Session row

    private func sessionRow(_ session: SleepReport) -> some View {
        Button {
            appState.selectedSession = session
            openWindow(id: "report")
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // ── Main info row ──────────────────────────────────────
                HStack(alignment: .center, spacing: DS.md) {
                    // Left severity bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(session.status.color)
                        .frame(width: 3, height: 44)

                    // Date column
                    VStack(alignment: .leading, spacing: 1) {
                        Text(shortDayName(session.sleepStart))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.wtLabel)
                        Text(shortMonthDay(session.sleepStart))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.wtLabelTert)
                    }
                    .frame(width: 72, alignment: .leading)

                    // Duration
                    Text(session.durationHours < 0.1 ? "< 1m" : session.duration.formattedDuration)
                        .font(.system(size: 22, weight: .light, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(Color.wtLabel)
                        .frame(width: 92, alignment: .leading)

                    // Mini wake timeline — fills remaining width
                    miniTimeline(session)
                        .frame(maxWidth: .infinity)

                    // Battery
                    batteryColumn(session)
                        .frame(width: 64, alignment: .trailing)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.wtLabelTert)
                }
                .padding(.leading, DS.md)
                .padding(.trailing, DS.md)
                .padding(.top, 10)

                // ── Detail row ─────────────────────────────────────────
                HStack(spacing: 0) {
                    // Indent to align under date column (3px bar + md gap + 72 date + md gap)
                    Color.clear.frame(width: 3 + DS.md + CGFloat(72) + DS.md)

                    HStack(spacing: DS.md) {
                        // Sleep → wake times
                        HStack(spacing: 4) {
                            Text(session.sleepStart.shortTimeNoAmPm)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color.wtLabelTert)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 7))
                                .foregroundStyle(Color.wtLabelTert.opacity(0.4))
                            Text(session.wakeEnd.shortTime)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color.wtLabelTert)
                        }

                        if session.wakeCount > 0 {
                            wakeCountChip(session)
                        } else {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.18, green: 0.84, blue: 0.58))
                                Text("No interruptions")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.wtLabelTert)
                            }
                        }

                        Spacer()

                        // Top finding teaser
                        if let top = session.findings.first(where: { $0.severity > .normal }) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(top.severity.color)
                                    .frame(width: 5, height: 5)
                                Text(top.headline)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.wtLabelSec)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(maxWidth: 230, alignment: .leading)
                        }
                    }
                    .padding(.trailing, DS.md)
                }
                .padding(.bottom, 10)
                .padding(.top, 3)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(hoveredId == session.id
                          ? Color.accentColor.opacity(0.06)
                          : Color.wtSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        hoveredId == session.id
                            ? Color.accentColor.opacity(0.22)
                            : Color.wtBorder,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                hoveredId = hovering ? session.id : nil
            }
        }
    }

    // MARK: - Sub-components

    private func miniTimeline(_ session: SleepReport) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let total = session.duration
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.wtBorder.opacity(0.15))
                    .frame(height: 2)
                ForEach(session.wakeEvents) { event in
                    let frac = total > 0
                        ? event.timestamp.timeIntervalSince(session.sleepStart) / total
                        : 0
                    let size: CGFloat = event.isDarkWake ? 3.5 : 6.5
                    Circle()
                        .fill(event.category.sparkColor.opacity(event.isDarkWake ? 0.45 : 0.85))
                        .frame(width: size, height: size)
                        .offset(x: max(0, min(w - size, CGFloat(frac) * w - size / 2)))
                }
            }
            .frame(height: 12)
        }
        .frame(height: 12)
    }

    @ViewBuilder
    private func batteryColumn(_ session: SleepReport) -> some View {
        if session.wasCharging {
            Label("Charged", systemImage: "bolt.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color(red: 0.18, green: 0.84, blue: 0.58))
                .labelStyle(.titleAndIcon)
        } else if let b = session.batteryAtSleep, let a = session.batteryAtWake {
            let drain = b - a
            VStack(alignment: .trailing, spacing: 2) {
                Text(drain > 0.5 ? "−\(Int(drain))%" : "stable")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(batteryColor(drain: drain, rate: session.drainRate))
                if let rate = session.drainRate, drain > 0.5 {
                    Text(String(format: "%.1f%%/hr", rate))
                        .font(.system(size: 9))
                        .foregroundStyle(Color.wtLabelTert)
                }
            }
        } else {
            Text("—")
                .font(.system(size: 13))
                .foregroundStyle(Color.wtLabelTert)
        }
    }

    private func wakeCountChip(_ session: SleepReport) -> some View {
        let dominant = session.wakeCategoryBreakdown.sorted { $0.count > $1.count }.first
        return HStack(spacing: 3) {
            if let cat = dominant?.category {
                Image(systemName: cat.systemImage)
                    .font(.system(size: 8))
                    .foregroundStyle(cat.sparkColor.opacity(0.85))
            }
            Text("\(session.wakeCount)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.wtLabelSec)
            Text(session.wakeCount == 1 ? "wake" : "wakes")
                .font(.system(size: 10))
                .foregroundStyle(Color.wtLabelTert)
        }
    }

    // MARK: - Empty state

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

    private func batteryColor(drain: Double, rate: Double?) -> Color {
        guard let r = rate else { return drain > 15 ? Color.statusElevated : Color.wtLabelSec }
        switch r {
        case ..<1.5:    return Color.wtLabelSec
        case 1.5..<2.5: return Color.statusNotice
        case 2.5..<4:   return Color.statusElevated
        default:        return Color.statusCritical
        }
    }

    private func shortDayName(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }

    private func shortMonthDay(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }

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

#Preview("Rich history") {
    HistoryView()
        .environmentObject(AppState.preview(sessions: MockData.history, battery: 72))
        .frame(width: 660, height: 560)
}

#Preview("Empty") {
    HistoryView()
        .environmentObject(AppState.preview(sessions: [], battery: 80))
        .frame(width: 660, height: 560)
}
