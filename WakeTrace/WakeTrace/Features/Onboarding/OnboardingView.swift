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
