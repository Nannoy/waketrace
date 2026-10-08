import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openWindow) private var openWindow

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
            Text("Loading last sleep…")
                .font(.system(size: 13))
                .foregroundStyle(Color.wtLabelSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.xl)
    }

    private func lastSessionContent(_ session: SleepReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Last Sleep")
                .sectionHeader()
                .padding(.horizontal, DS.md)
                .padding(.top, DS.md)
                .padding(.bottom, 10)

            // Duration + status
            HStack(alignment: .firstTextBaseline, spacing: DS.sm) {
                Text(session.duration.formattedDuration)
                    .font(.system(size: 28, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(Color.wtLabel)
                Spacer()
                StatusBadge(status: session.status)
            }
            .padding(.horizontal, DS.md)

            Text(session.relativeLabel)
                .font(.system(size: 12))
                .foregroundStyle(Color.wtLabelSec)
                .padding(.horizontal, DS.md)
                .padding(.top, 2)

            // Battery row
            if let before = session.batteryAtSleep, let after = session.batteryAtWake {
                HStack(spacing: DS.xs) {
                    Text("Battery")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.wtLabelSec)
                    Text("\(Int(before))%")
                        .monoNum(12, weight: .medium)
                        .foregroundStyle(Color.wtLabelSec)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.wtLabelTert)
                    Text("\(Int(after))%")
                        .monoNum(12, weight: .medium)
                        .foregroundStyle(Color.wtLabelSec)
                    let delta = Int(before - after)
                    Text("–\(delta)%")
                        .monoNum(12, weight: .semibold)
                        .foregroundStyle(session.status == .normal ? Color.wtLabelSec : session.status.color)
                }
                .padding(.horizontal, DS.md)
                .padding(.top, DS.sm)
            } else if session.wasCharging {
                Label("Plugged in during sleep", systemImage: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.wtLabelTert)
                    .padding(.horizontal, DS.md)
                    .padding(.top, DS.sm)
            }

            // Top finding (non-normal only)
            if let topFinding = session.findings.first(where: { $0.severity > .normal }) {
                Text(topFinding.headline)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.wtLabelSec)
                    .lineLimit(2)
                    .padding(.horizontal, DS.md)
                    .padding(.top, DS.sm)
            }

            // View Report button
            Button {
                appState.selectedSession = session
                openWindow(id: "report")
            } label: {
                Text("View Full Report")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(0.10))
            )
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, DS.md)
            .padding(.vertical, DS.md)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.sm) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 22))
                .foregroundStyle(Color.wtLabelTert)
            Text("No sleep data yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.wtLabel)
            Text("WakeTrace will analyse your Mac's next sleep session automatically.")
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
                Text("No application is preventing sleep.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelTert)
            } else {
                let names = appState.activeAssertions.prefix(2).joined(separator: ", ")
                let suffix = appState.activeAssertions.count > 2 ? " +\(appState.activeAssertions.count - 2) more" : ""
                HStack(spacing: 4) {
                    Image(systemName: "nosign")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.statusNotice)
                    Text("\(names)\(suffix) is preventing sleep.")
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
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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
