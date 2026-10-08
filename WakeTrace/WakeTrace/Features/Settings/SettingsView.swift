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
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue  // revert on failure
                        }
                    }
                Toggle("Show in Dock", isOn: $showInDock)
            }

            Section("Data Retention") {
                Picker("Keep history for", selection: $retentionDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                    Text("Forever").tag(0)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)

                Text("Older sessions are automatically removed.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelTert)
            }

            Section("Menu Bar") {
                Text("WakeTrace lives exclusively in the menu bar. Click the waveform icon to view your last session at a glance.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtLabelTert)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .padding(DS.sm)
    }

    // MARK: - Notifications

    private var notificationsTab: some View {
        Form {
            Section("Alert me when…") {
                Toggle("Severe battery drain detected", isOn: $notifyOnCritical)
                Toggle("Elevated battery drain detected", isOn: $notifyOnElevated)
            }

            Section("About Notifications") {
                Text("Notifications appear after your Mac wakes up. WakeTrace requires Notifications permission in System Settings.")
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
                    icon: "battery.75percent",
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
                Button("Delete All Session Data") {
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
