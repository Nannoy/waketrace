import SwiftUI

struct TimelineView: View {
    let session: SleepReport
    @State private var trackProgress: Double = 0
    @State private var revealCount: Int = 0

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

            WTCard(padding: DS.lg) {
                if session.wakeEvents.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: DS.md) {
                        timeLabels
                        timelineLane
                        categoryLegend
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                trackProgress = 1.0
            }
            for i in 0..<session.wakeEvents.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.035) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        revealCount = i + 1
                    }
                }
            }
        }
    }

    // MARK: - Time labels

    private var timeLabels: some View {
        HStack {
            Text(session.sleepStart.shortTimeNoAmPm)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.wtLabelTert)
            Spacer()
            Text(session.wakeEnd.shortTimeNoAmPm)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.wtLabelTert)
        }
    }

    // MARK: - Lane

    private var timelineLane: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let total = session.duration

            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.wtBorder.opacity(0.12))
                    .frame(height: 2)

                // Animated fill
                Capsule()
                    .fill(Color.wtBorder.opacity(0.35))
                    .frame(width: w * trackProgress, height: 2)

                // Event dots
                ForEach(Array(session.wakeEvents.enumerated()), id: \.element.id) { idx, event in
                    let frac = total > 0
                        ? event.timestamp.timeIntervalSince(session.sleepStart) / total
                        : 0
                    let cx = CGFloat(frac) * w
                    let size: CGFloat = event.isDarkWake ? 6 : 10
                    let shown = idx < revealCount

                    ZStack {
                        if !event.isDarkWake {
                            Circle()
                                .fill(event.category.sparkColor.opacity(0.20))
                                .frame(width: size + 7, height: size + 7)
                        }
                        Circle()
                            .fill(event.category.sparkColor)
                            .frame(width: size, height: size)
                        if !event.isDarkWake {
                            Circle()
                                .strokeBorder(event.category.sparkColor.opacity(0.45), lineWidth: 1)
                                .frame(width: size + 3, height: size + 3)
                        }
                    }
                    .offset(x: max(0, min(w - size, cx - size / 2)))
                    .scaleEffect(shown ? 1 : 0.01)
                    .opacity(shown ? 1 : 0)
                }
            }
            .frame(height: 18)
        }
        .frame(height: 18)
    }

    // MARK: - Legend

    private var categoryLegend: some View {
        let breakdown = session.wakeCategoryBreakdown
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.md) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.wtLabelTert.opacity(0.5))
                        .frame(width: 5, height: 5)
                    Text("Dark wake")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.wtLabelTert)
                }
                ForEach(breakdown, id: \.category) { item in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(item.category.sparkColor)
                            .frame(width: 7, height: 7)
                        Text("\(item.count) \(item.category.displayName)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.wtLabelSec)
                    }
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        HStack(spacing: DS.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(red: 0.18, green: 0.84, blue: 0.58))
            VStack(alignment: .leading, spacing: 2) {
                Text("No wake events recorded")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.wtLabel)
                Text("Your Mac slept without interruption.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelSec)
            }
        }
    }
}

// MARK: - WakeCategory sparkColor

extension WakeCategory {
    var sparkColor: Color {
        switch self {
        case .bluetooth:   return Color(red: 0.30, green: 0.53, blue: 0.92)
        case .network:     return Color(red: 0.18, green: 0.84, blue: 0.58)
        case .maintenance: return Color(red: 0.58, green: 0.58, blue: 0.68)
        case .timer:       return Color(red: 0.70, green: 0.52, blue: 0.92)
        case .lid:         return Color(red: 0.30, green: 0.82, blue: 0.78)
        case .user:        return Color(red: 0.30, green: 0.82, blue: 0.78)
        case .power:       return Color(red: 0.98, green: 0.76, blue: 0.22)
        case .application: return Color(red: 0.98, green: 0.50, blue: 0.30)
        case .unknown:     return Color(red: 0.55, green: 0.55, blue: 0.62)
        }
    }
}

#Preview("Active timeline") {
    TimelineView(session: MockData.previewSession)
        .frame(width: 680)
        .padding()
}

#Preview("Empty timeline") {
    TimelineView(session: MockData.previewHistory.dropFirst().first ?? MockData.previewSession)
        .frame(width: 680)
        .padding()
}
