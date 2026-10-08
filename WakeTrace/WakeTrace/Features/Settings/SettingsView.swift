import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var launchAtLogin: Bool = (SMAppService.mainApp.status == .enabled)
    @AppStorage("showInDock")        private var showInDock       = false
    @AppStorage("notifyOnCritical")  private var notifyOnCritical = true
    @AppStorage("notifyOnElevated")  private var notifyOnElevated = false
    @AppStorage("retentionDays")     private var retentionDays    = 30

    private enum Tab: String, CaseIterable {
        case general = "General"
        case notifications = "Notifications"
        case privacy = "Privacy"
    }

    @State private var activeTab: Tab = .general

    var body: some View {
        TabView(selection: $activeTab) {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(Tab.general)

            notificationsTab
                .tabItem { Label("Notifications", systemImage: "bell") }
                .tag(Tab.notifications)

            privacyTab
                .tabItem { Label("Privacy", systemImage: "lock.shield") }
                .tag(Tab.privacy)
        }
        .frame(width: 440, height: 340)
        .background(Color.wtBackground)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Open automatically when I log in", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
                Toggle("Show icon in Dock", isOn: $showInDock)
            }

            Section("Sleep History") {
                Picker("Save history for", selection: $retentionDays) {
                    Text("1 week").tag(7)
                    Text("2 weeks").tag(14)
                    Text("1 month").tag(30)
                    Text("3 months").tag(90)
                    Text("Keep forever").tag(0)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)

                Text("Sleep sessions older than this are deleted automatically.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelTert)
            }

            Section {
                HStack(spacing: DS.md) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.98, green: 0.76, blue: 0.22))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enjoying WakeTrace?")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.wtLabel)
                        Text("Star us on GitHub — it helps others discover the app.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.wtLabelSec)
                    }
                    Spacer()
                    Button("Star on GitHub") {
                        NSWorkspace.shared.open(URL(string: "https://github.com/Nannoy/waketrace")!)
                    }
                    .buttonStyle(.bordered)
                    .font(.system(size: 12))
                    .controlSize(.small)
                }
                .padding(.vertical, 2)
            }

            Section("Where to find WakeTrace") {
                Text("WakeTrace lives in your menu bar — look for the waveform icon at the top of your screen. It never appears in the Dock.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelTert)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Replay Introduction…") {
                    UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
                    NotificationCenter.default.post(name: .openOnboardingIfNeeded, object: nil)
                }
                .buttonStyle(.link)
                .font(.system(size: 12))
            }
        }
        .formStyle(.grouped)
        .padding(DS.sm)
    }

    // MARK: - Notifications

    private var notificationsTab: some View {
        Form {
            Section("Send me a notification when…") {
                Toggle("Battery drained significantly overnight", isOn: $notifyOnCritical)
                Toggle("Battery drain is higher than normal", isOn: $notifyOnElevated)
            }

            Section("About Notifications") {
                Text("Notifications appear shortly after your Mac wakes up. You can grant permission in System Settings → Notifications.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelTert)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Notification Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
                }
                .buttonStyle(.link)
                .font(.system(size: 12))
            }
        }
        .formStyle(.grouped)
        .padding(DS.sm)
    }

    // MARK: - Privacy

    private var privacyTab: some View {
        Form {
            Section("Data Access") {
                settingRow(
                    icon: "doc.text.magnifyingglass",
                    title: "System Logs",
                    detail: "WakeTrace reads sleep/wake entries from the macOS unified log using `log show`. Only powerd entries are queried."
                )
                settingRow(
                    icon: "battery.50percent",
                    title: "Battery",
                    detail: "Battery level is read via IOKit. No data is written or transmitted."
                )
                settingRow(
                    icon: "network.slash",
                    title: "No Network Access",
                    detail: "WakeTrace has no network entitlements. All data stays on-device."
                )
            }

            Section {
                Button("Erase All Sleep History") {
                    appState.sessions = []
                }
                .foregroundStyle(Color.statusCritical)
            }
        }
        .formStyle(.grouped)
        .padding(DS.sm)
    }

    private func settingRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: DS.md) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.wtLabel)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelSec)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
