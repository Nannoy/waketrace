import SwiftUI

struct TimelineView: View {
    let session: SleepReport

    // Group events into 30-minute buckets for visual density
    private var buckets: [(hour: String, events: [WakeEventSummary])] {
        guard !session.wakeEvents.isEmpty else { return [] }
        var groups: [String: [WakeEventSummary]] = [:]
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"

        let bucketSize: TimeInterval = 1800 // 30 min
        for evt in session.wakeEvents {
            let bucketStart = Date(timeIntervalSinceReferenceDate:
                floor(evt.timestamp.timeIntervalSinceReferenceDate / bucketSize) * bucketSize)
            let key = fmt.string(from: bucketStart)
            groups[key, default: []].append(evt)
        }

        return groups
            .map { (hour: $0.key, events: $0.value) }
            .sorted { a, b in
                guard let ta = a.events.first?.timestamp,
                      let tb = b.events.first?.timestamp else { return false }
                return ta < tb
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            HStack {
                Text("Wake Timeline")
                    .sectionHeader()
                Spacer()
                Text("\(session.wakeCount) events over \(session.duration.formattedHours)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelTert)
            }

            WTCard(padding: 0) {
                if session.wakeEvents.isEmpty {
                    Text("No wake events recorded.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.wtLabelTert)
                        .padding(DS.lg)
                } else {
                    VStack(spacing: 0) {
                        // Sparkline overview
                        sparkline
                            .padding(.horizontal, DS.lg)
                            .padding(.top, DS.md)
                            .padding(.bottom, DS.sm)

                        WTDivider()

                        // Category legend
                        categoryLegend

                        WTDivider()

                        // Grouped event list
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: []) {
                                ForEach(buckets.prefix(20), id: \.hour) { bucket in
                                    timelineBucket(bucket)
                                }
                                if buckets.count > 20 {
                                    Text("+ \(buckets.count - 20) more buckets not shown")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.wtLabelTert)
                                        .padding(DS.md)
                                }
                            }
                        }
                        .frame(maxHeight: 260)
                    }
                }
            }
        }
    }

    // MARK: - Sparkline

    private var sparkline: some View {
        GeometryReader { geo in
            let total = session.duration
            let width = geo.size.width

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.wtBorder.opacity(0.3))
                    .frame(height: 4)

                // Sleep / wake markers
                ForEach(session.wakeEvents) { event in
                    let offset = total > 0
                        ? CGFloat(event.timestamp.timeIntervalSince(session.sleepStart) / total) * width
                        : 0
                    Circle()
                        .fill(event.category.sparkColor)
                        .frame(width: event.isDarkWake ? 5 : 8, height: event.isDarkWake ? 5 : 8)
                        .offset(x: max(0, offset - 3))
                }
            }
            .frame(height: 8)
        }
        .frame(height: 8)
    }

    // MARK: - Legend

    private var categoryLegend: some View {
        let breakdown = session.wakeCategoryBreakdown

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.lg) {
                ForEach(breakdown, id: \.category) { item in
                    HStack(spacing: DS.xs) {
                        Circle()
                            .fill(item.category.sparkColor)
                            .frame(width: 6, height: 6)
                        Text("\(item.count) \(item.category.displayName)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.wtLabelSec)
                    }
                }
            }
            .padding(.horizontal, DS.lg)
            .padding(.vertical, DS.sm)
        }
    }

    // MARK: - Bucket row

    private func timelineBucket(_ bucket: (hour: String, events: [WakeEventSummary])) -> some View {
        HStack(alignment: .top, spacing: DS.md) {
            Text(bucket.hour)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.wtLabelTert)
                .frame(width: 56, alignment: .trailing)
                .padding(.top, 3)

            // Timeline dot + line
            VStack(spacing: 0) {
                Circle()
                    .fill(bucket.events.first.map { $0.category.sparkColor } ?? Color.wtBorder)
                    .frame(width: 7, height: 7)
                    .padding(.top, 4)
                Rectangle()
                    .fill(Color.wtBorder.opacity(0.3))
                    .frame(width: 1)
            }

            // Event chips
            VStack(alignment: .leading, spacing: 3) {
                ForEach(bucket.events) { event in
                    eventChip(event)
                }
            }
            .padding(.bottom, DS.sm)

            Spacer()
        }
        .padding(.horizontal, DS.md)
        .padding(.top, DS.sm)
    }

    private func eventChip(_ event: WakeEventSummary) -> some View {
        HStack(spacing: 4) {
            Image(systemName: event.category.systemImage)
                .font(.system(size: 9))
                .foregroundStyle(event.category.sparkColor)
            Text(event.category.displayName)
                .font(.system(size: 11))
                .foregroundStyle(Color.wtLabelSec)
            if !event.isDarkWake {
                Text("Full Wake")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.wtLabelTert)
            }
        }
    }
}

// MARK: - WakeCategory helpers for timeline

extension WakeCategory {
    var sparkColor: Color {
        switch self {
        case .bluetooth:   return Color(red: 0.30, green: 0.53, blue: 0.90)
        case .network:     return Color(red: 0.30, green: 0.76, blue: 0.60)
        case .maintenance: return Color.wtLabelTert
        case .timer:       return Color(red: 0.70, green: 0.55, blue: 0.88)
        case .lid:         return Color.statusNormal
        case .user:        return Color.statusNormal
        case .power:       return Color(red: 0.98, green: 0.72, blue: 0.30)
        case .application: return Color.statusElevated
        case .unknown:     return Color.wtLabelTert
        }
    }
}
