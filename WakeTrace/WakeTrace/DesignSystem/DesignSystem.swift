import SwiftUI

// MARK: - Adaptive Colors

extension Color {
    // ── Semantic status ──────────────────────────────────────────────────────
    static let statusNormal   = Color(NSColor(name: nil) { app in
        app.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            ? NSColor(white: 0.55, alpha: 1)
            : NSColor(white: 0.52, alpha: 1)
    })
    static let statusNotice   = Color(NSColor.systemOrange).opacity(0.85)
    static let statusElevated = Color(NSColor.systemOrange)
    static let statusCritical = Color(NSColor.systemRed)

    // ── Surfaces ─────────────────────────────────────────────────────────────
    static let wtBackground    = Color(NSColor.windowBackgroundColor)
    static let wtSurface       = Color(NSColor.controlBackgroundColor)
    static let wtBorder        = Color(NSColor.separatorColor)

    // ── Text ─────────────────────────────────────────────────────────────────
    static let wtLabel         = Color(NSColor.labelColor)
    static let wtLabelSec      = Color(NSColor.secondaryLabelColor)
    static let wtLabelTert     = Color(NSColor.tertiaryLabelColor)
}

// MARK: - Spacing

enum DS {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Typography helpers

extension View {
    func sectionHeader() -> some View {
        self.font(.system(size: 10, weight: .semibold, design: .default))
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(Color.wtLabelTert)
    }

    func monoNum(_ size: CGFloat = 14, weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: size, weight: weight, design: .monospaced))
            .monospacedDigit()
    }
}

// MARK: - WTCard

struct WTCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DS.lg

    init(padding: CGFloat = DS.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.wtSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.wtBorder, lineWidth: 0.5)
            )
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Text(status.label)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.4)
            .foregroundStyle(status == .normal ? Color.wtLabelSec : status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(status == .normal
                          ? Color.wtBorder.opacity(0.6)
                          : status.color.opacity(0.10))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        status == .normal
                            ? Color.clear
                            : status.color.opacity(0.25),
                        lineWidth: 0.5
                    )
            )
    }
}

// MARK: - SeverityBar (left-edge accent on findings)

struct SeverityBar: View {
    let severity: FindingSeverity

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(severity.color)
            .frame(width: 3)
            .opacity(severity == .normal ? 0.35 : 0.85)
    }
}

// MARK: - WTDivider

struct WTDivider: View {
    var body: some View {
        Divider()
            .opacity(0.5)
    }
}

// MARK: - Formatted time

extension TimeInterval {
    var formattedDuration: String {
        let h = Int(self) / 3600
        let m = (Int(self) % 3600) / 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    var formattedHours: String {
        let h = Int(self) / 3600
        let m = (Int(self) % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }
}

extension Date {
    var shortTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: self)
    }

    var shortTimeNoAmPm: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: self)
    }
}

// MARK: - BatteryDrainMultiplierText

struct DrainMultiplierText: View {
    let multiplier: Double

    var body: some View {
        Text(formatted)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(color)
    }

    private var formatted: String {
        if multiplier < 1.5 { return "Normal" }
        return String(format: "%.1f× normal", multiplier)
    }

    private var color: Color {
        switch multiplier {
        case ..<1.5:   return .statusNormal
        case 1.5..<2:  return .statusNotice
        case 2..<4:    return .statusElevated
        default:        return .statusCritical
        }
    }
}
