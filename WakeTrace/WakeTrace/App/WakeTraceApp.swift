import SwiftUI

@main
struct WakeTraceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        // ── Menu bar ───────────────────────────────────────────────────────
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
        } label: {
            Image(systemName: "waveform")
                .symbolRenderingMode(.hierarchical)
                .imageScale(.medium)
        }
        .menuBarExtraStyle(.window)

        // ── Report window ──────────────────────────────────────────────────
        WindowGroup(id: "report") {
            ReportWindowView()
                .environmentObject(appState)
                .frame(minWidth: 680, minHeight: 560)
                .navigationTitle("Sleep Report")
        }
        .defaultSize(width: 760, height: 680)
        .windowResizability(.contentSize)

        // ── History window ─────────────────────────────────────────────────
        WindowGroup(id: "history") {
            HistoryView()
                .environmentObject(appState)
                .frame(minWidth: 520, minHeight: 420)
                .navigationTitle("History")
        }
        .defaultSize(width: 600, height: 520)
        .windowResizability(.contentSize)

        // ── Settings ───────────────────────────────────────────────────────
        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        // ── Onboarding ─────────────────────────────────────────────────────
        WindowGroup(id: "onboarding") {
            OnboardingView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 540, height: 580)
        .windowResizability(.contentSize)
    }
}
