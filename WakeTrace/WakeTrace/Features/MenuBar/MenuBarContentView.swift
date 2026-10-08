import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openWindow)   private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            header
            WTDivider()
            lastSessionSection
            WTDivider()
            currentStatusSection
            WTDivider()
            footerActions
        }
        .frame(width: 320)
        .background(Color.wtBackground)
        .onAppear { appState.refreshBattery() }
        .onReceive(NotificationCenter.default.publisher(for: .openOnboardingIfNeeded)) { _ in
            openWindow(id: "onboarding")
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: DS.sm) {
            Image(systemName: "waveform")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.accentColor)
            Text("WakeTrace")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.wtLabel)
            Spacer()
            if appState.isAnalyzing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                    Text("Analysing…")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.wtLabelTert)
                }
            }
        }
        .padding(.horizontal, DS.md)
        .padding(.vertical, 12)
    }

    // MARK: - Last Session

    private var lastSessionSection: some View {
        Group {
            if appState.isAnalyzing && appState.sessions.isEmpty {
                analyzingState
            } else if let session = appState.lastSession {
                lastSessionContent(session)
            } else {
                emptyState
            }
        }
    }

    private var analyzingState: some View {
        VStack(spacing: DS.sm) {
            ProgressView()
            Text("Checking last sleep…")
                .font(.system(size: 13))
                .foregroundStyle(Color.wtLabelSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.xl)
    }

    private func lastSessionContent(_ session: SleepReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header — show relative label only when it adds info
            HStack {
                Text("Last Sleep")
                    .sectionHeader()
                Spacer()
                if session.relativeLabel != "Last Sleep" {
                    Text(session.relativeLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.wtLabelTert)
                }
            }
            .padding(.horizontal, DS.md)
            .padding(.top, DS.md)
            .padding(.bottom, 10)

            // Duration + status badge
            HStack(alignment: .center, spacing: DS.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Group {
                        if session.durationHours < 0.1 {
                            Text("< 1 min")
                                .foregroundStyle(Color.wtLabelTert)
                        } else {
                            Text(session.duration.formattedDuration)
                                .foregroundStyle(Color.wtLabel)
                        }
                    }
                    .font(.system(size: 30, weight: .light))
                    .monospacedDigit()

                    // Sleep → wake times
                    HStack(spacing: 6) {
                        Text(session.sleepStart.shortTime)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.wtLabelTert)
                        Text(session.wakeEnd.shortTime)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelSec)
                }

                Spacer()
                StatusBadge(status: session.status)
            }
            .padding(.horizontal, DS.md)

            // Battery pill — only if meaningful drain
            if let before = session.batteryAtSleep, let after = session.batteryAtWake {
                let drain = Int(before - after)
                HStack(spacing: 6) {
                    Image(systemName: "battery.50percent")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.wtLabelTert)
                    if session.wasCharging {
                        Text("Charged while sleeping")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.wtLabelSec)
                    } else if drain <= 0 {
                        Text("\(Int(after))% — no drain")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.wtLabelSec)
                    } else {
                        Text("\(Int(before))% → \(Int(after))%")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.wtLabelSec)
                        Text("(−\(drain)%)")
                            .font(.system(size: 11, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(drain > 15 ? session.status.color : Color.wtLabelSec)
                    }
                }
                .padding(.horizontal, DS.md)
                .padding(.top, 8)
            }

            // Top finding — shown with severity colour dot
            if let top = session.findings.first(where: { $0.severity > .normal }) {
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(top.severity.color)
                        .frame(width: 6, height: 6)
                        .padding(.top, 3)
                    Text(top.headline)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.wtLabelSec)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, DS.md)
                .padding(.top, 8)
            }

            // View Full Report — subtle right-aligned link
            HStack {
                Spacer()
                Button {
                    appState.selectedSession = session
                    openWindow(id: "report")
                } label: {
                    HStack(spacing: 4) {
                        Text("View Full Report")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DS.md)
            .padding(.top, 10)
            .padding(.bottom, DS.md)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.sm) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 22))
                .foregroundStyle(Color.wtLabelTert)
            Text("No sleep recorded yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.wtLabel)
            Text("Close your Mac's lid tonight and open WakeTrace tomorrow — your first report will be ready.")
                .font(.system(size: 12))
                .foregroundStyle(Color.wtLabelSec)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.xl)
        .padding(.horizontal, DS.lg)
    }

    // MARK: - Current Status

    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: DS.xs) {
            Text("Right Now")
                .sectionHeader()
                .padding(.bottom, 2)

            HStack(spacing: DS.sm) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                Text("Awake")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.wtLabel)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: batteryIcon)
                        .font(.system(size: 11))
                        .foregroundStyle(appState.isCharging ? Color.green : Color.wtLabelSec)
                    Text("\(Int(appState.currentBatteryLevel))%")
                        .monoNum(12)
                        .foregroundStyle(Color.wtLabelSec)
                }
            }

            // Sleep assertions
            if appState.activeAssertions.isEmpty {
                Text("Nothing is blocking your Mac from sleeping.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelTert)
            } else {
                let names = appState.activeAssertions.prefix(2).joined(separator: ", ")
                let suffix = appState.activeAssertions.count > 2 ? " +\(appState.activeAssertions.count - 2) more" : ""
                HStack(spacing: 4) {
                    Image(systemName: "nosign")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.statusNotice)
                    Text("\(names)\(suffix) is keeping your Mac awake.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.statusNotice)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, DS.md)
        .padding(.vertical, 12)
    }

    // Real battery icon based on current level
    private var batteryIcon: String {
        if appState.isCharging { return "battery.100percent.bolt" }
        switch appState.currentBatteryLevel {
        case 76...:  return "battery.100percent"
        case 51...:  return "battery.75percent"
        case 26...:  return "battery.50percent"
        case 11...:  return "battery.25percent"
        default:     return "battery.0percent"
        }
    }

    // MARK: - Footer

    private var footerActions: some View {
        HStack(spacing: 0) {
            menuButton("History", icon: "clock") {
                openWindow(id: "history")
            }
            menuButton("Settings", icon: "gearshape") {
                openSettings()
            }
            menuButton("Quit", icon: "power") {
                NSApp.terminate(nil)
            }
        }
        .padding(.vertical, DS.xs)
    }

    private func menuButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(Color.wtLabelSec)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffect()
    }
}

// MARK: - Hover effect

struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.wtBorder.opacity(0.6) : Color.clear)
            )
            .onHover { isHovered = $0 }
    }
}

extension View {
    func hoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }
}

// Shows your real last session (falls back to analyzing state if no sleep yet)
#Preview("Live data") {
    MenuBarContentView()
        .environmentObject(AppState())
        .frame(width: 320)
}

// Always shows a rich mock session — good for design work
#Preview("Mock – Abnormal") {
    MenuBarContentView()
        .environmentObject(AppState.preview(
            sessions: [MockData.abnormalSession],
            battery: 61
        ))
        .frame(width: 320)
}

#Preview("Mock – Normal") {
    MenuBarContentView()
        .environmentObject(AppState.preview(
            sessions: [MockData.normalSession],
            battery: 87
        ))
        .frame(width: 320)
}

#Preview("Empty state") {
    MenuBarContentView()
        .environmentObject(AppState.preview(sessions: [], battery: 92))
        .frame(width: 320)
}
