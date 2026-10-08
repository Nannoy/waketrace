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
        }
        .padding(.horizontal, DS.md)
        .padding(.vertical, 12)
    }

    // MARK: - Last Session

    private var lastSessionSection: some View {
        Group {
            if let session = appState.lastSession {
                lastSessionContent(session)
            } else {
                emptyState
            }
        }
    }

    private func lastSessionContent(_ session: SleepReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Last Sleep")
                .sectionHeader()
                .padding(.horizontal, DS.md)
                .padding(.top, DS.md)
                .padding(.bottom, 10)

            // Duration + status row
            HStack(alignment: .firstTextBaseline, spacing: DS.sm) {
                Text(session.duration.formattedDuration)
                    .font(.system(size: 28, weight: .light, design: .default))
                    .monospacedDigit()
                    .foregroundStyle(Color.wtLabel)
                Spacer()
                StatusBadge(status: session.status)
            }
            .padding(.horizontal, DS.md)

            Text(session.nightLabel)
                .font(.system(size: 12))
                .foregroundStyle(Color.wtLabelSec)
                .padding(.horizontal, DS.md)
                .padding(.top, 2)

            // Battery
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
                    Text("–\(Int(before - after))%")
                        .monoNum(12, weight: .semibold)
                        .foregroundStyle(session.status == .normal ? Color.wtLabelSec : session.status.color)
                }
                .padding(.horizontal, DS.md)
                .padding(.top, DS.sm)
            }

            // Top finding headline
            if let topFinding = session.findings.filter({ $0.severity > .normal }).first {
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
                .font(.system(size: 24))
                .foregroundStyle(Color.wtLabelTert)
            Text("No sleep reports yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.wtLabel)
            Text("Close your Mac and WakeTrace will\nanalyse the next sleep session.")
                .font(.system(size: 12))
                .foregroundStyle(Color.wtLabelSec)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.xl)
        .padding(.horizontal, DS.md)
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
                HStack(spacing: 3) {
                    Image(systemName: appState.isCharging ? "bolt.fill" : "battery.75percent")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.wtLabelSec)
                    Text("\(Int(appState.currentBatteryLevel))%")
                        .monoNum(12)
                        .foregroundStyle(Color.wtLabelSec)
                }
            }

            Text("No application is preventing sleep.")
                .font(.system(size: 11))
                .foregroundStyle(Color.wtLabelTert)
        }
        .padding(.horizontal, DS.md)
        .padding(.vertical, 12)
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

// Simple hover effect helper
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

#Preview {
    MenuBarContentView()
        .environmentObject(AppState())
}
