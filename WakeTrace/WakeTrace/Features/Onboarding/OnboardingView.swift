import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform",
            title: "Meet WakeTrace",
            body: "WakeTrace monitors your Mac while it sleeps and gives you a clear picture of what happened — battery drain, wake-ups, and why.",
            accentColor: .accentColor
        ),
        OnboardingPage(
            icon: "lock.shield",
            title: "Your data, on-device",
            body: "WakeTrace reads macOS system logs that already exist on your Mac. Nothing leaves your machine. No account. No telemetry.",
            accentColor: .statusNormal
        ),
        OnboardingPage(
            icon: "checkmark.circle",
            title: "You're all set",
            body: "WakeTrace lives in your menu bar. Sleep your Mac tonight and open the app tomorrow morning to see your first report.",
            accentColor: .statusNormal
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon + content
            let current = pages[page]
            Group {
                if page == pages.count - 1 {
                    menuBarCalloutPage
                } else {
                    VStack(spacing: DS.lg) {
                        ZStack {
                            Circle()
                                .fill(current.accentColor.opacity(0.08))
                                .frame(width: 80, height: 80)
                            Image(systemName: current.icon)
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(current.accentColor)
                        }

                        VStack(spacing: DS.sm) {
                            Text(current.title)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.wtLabel)
                                .multilineTextAlignment(.center)

                            Text(current.body)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.wtLabelSec)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .frame(maxWidth: 360)
                        }
                    }
                    .padding(.horizontal, DS.xxl)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: page)
            .id(page)

            Spacer()

            // Page dots
            HStack(spacing: DS.sm) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color.accentColor : Color.wtBorder)
                        .frame(width: i == page ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.3), value: page)
                }
            }
            .padding(.bottom, DS.xl)

            // Actions
            HStack {
                if page > 0 {
                    Button("Back") { page -= 1 }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.wtLabelSec)
                } else {
                    Spacer()
                }
                Spacer()
                if page < pages.count - 1 {
                    Button("Continue") { page += 1 }
                        .keyboardShortcut(.return)
                        .buttonStyle(WTPrimaryButtonStyle())
                } else {
                    Button("Get Started") {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        appState.isFirstLaunch = false
                        dismiss()
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(WTPrimaryButtonStyle())
                }
            }
            .padding(.horizontal, DS.xl)
            .padding(.bottom, DS.xl)
        }
        .background(Color.wtBackground)
        .frame(width: 540, height: 480)
    }

    // MARK: - Menu bar callout page

    private var menuBarCalloutPage: some View {
        VStack(spacing: DS.lg) {
            Text("You're all set")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.wtLabel)

            Text("WakeTrace lives in your menu bar — not in the Dock.")
                .font(.system(size: 14))
                .foregroundStyle(Color.wtLabelSec)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            // Mini menu bar mockup
            VStack(spacing: 8) {
                MenuBarMockup()
                    .frame(width: 340, height: 36)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                    Text("Click the waveform icon here to open WakeTrace")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.wtLabelSec)
                }
            }

            Text("Sleep your Mac tonight — your first report will be waiting in the morning.")
                .font(.system(size: 13))
                .foregroundStyle(Color.wtLabelTert)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .padding(.horizontal, DS.xxl)
    }
}

// Fake menu bar strip with a highlighted waveform icon
private struct MenuBarMockup: View {
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .windowBackgroundColor).opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.wtBorder, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            .overlay(alignment: .trailing) {
                HStack(spacing: 14) {
                    // Fake status items
                    ForEach(["wifi", "battery.75percent", "speaker.wave.1"], id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.wtLabelTert)
                    }

                    // Highlighted waveform — this is WakeTrace
                    ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.accentColor.opacity(pulse ? 0.18 : 0.1))
                            .frame(width: 28, height: 22)
                            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)

                        Image(systemName: "waveform")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.trailing, 14)
            }
            .overlay(alignment: .center) {
                // Fake clock
                Text(Date(), format: .dateTime.hour().minute())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.wtLabel)
            }
            .onAppear { pulse = true }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
    let accentColor: Color
}

struct WTPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, DS.lg)
            .padding(.vertical, DS.sm + 1)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.85 : 1))
            )
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
