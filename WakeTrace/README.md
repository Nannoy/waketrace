# WakeTrace — macOS App

The menu bar app component of WakeTrace. Built with SwiftUI, targets macOS 14+ on Apple Silicon.

## Building

```bash
# Install xcodegen if needed
brew install xcodegen

cd WakeTrace
xcodegen generate
xcodebuild -scheme WakeTrace -destination 'platform=macOS' build
```

The compiled app lands in Xcode's DerivedData. Because `LSUIElement = true`, there is no Dock icon — look for the waveform icon in your menu bar.

## Architecture

### Layer separation

```
App/            Entry point. Scene graph: MenuBarExtra, WindowGroup(report),
                WindowGroup(history), Settings, WindowGroup(onboarding).

Core/           Data layer. No SwiftUI imports.
  LogReader           Wraps `log show`, parses compact log format
  WakeClassifier      Maps Apple Silicon wake-reason strings to WakeCategory
  SessionAnalyzer     Produces ranked [Finding] from a SleepSession
  BaselineEngine      Rolling 14-session median for drain rate & wake rate
  SleepMonitor        NSWorkspace sleep/wake notification observer
  BatteryMonitor      IOKit one-shot battery snapshot
  NotificationManager UNUserNotificationCenter wrapper
  CoreModels          Internal types: WakeEvent, SleepSession, PowerAssertion
  SessionConverter    SleepSession → SleepReport (UI type)

Models/         UI-layer types: SleepReport, Finding, WakeEventSummary,
                SessionStatus, FindingSeverity, WakeCategory (with SwiftUI Color)

State/          AppState (ObservableObject), SessionStore (JSON persistence),
                MockData (development fixtures)

DesignSystem/   Color extensions, DS spacing constants, WTCard, StatusBadge,
                SeverityBar, WTDivider, typography helpers

Features/
  MenuBar/      MenuBarContentView — 320pt popover
  Report/       ReportView, BatteryCard, FindingsSection, TimelineView
  History/      HistoryView — sessions grouped by week
  Onboarding/   3-screen onboarding flow
  Settings/     GeneralTab, NotificationsTab, PrivacyTab
```

### Data flow

```
NSWorkspace notification
        │
        ▼
  SleepMonitor ──► AppState.sleepMonitorWillSleep  (snapshot battery)
                         │
             [Mac wakes up]
                         │
                         ▼
              AppState.analyzeSession
                  │           │
                  ▼           ▼
            LogReader    BatteryMonitor
                  │
                  ▼
           WakeClassifier
                  │
                  ▼
          SessionAnalyzer ──► [Finding]
                  │
                  ▼
          SessionConverter ──► SleepReport
                  │
          ┌───────┴────────┐
          ▼                ▼
     SessionStore    NotificationManager
    (JSON persist)   (UNUserNotification)
          │
          ▼
       AppState.sessions  (@Published)
          │
          ▼
    SwiftUI views re-render
```

### Design System

`DesignSystem.swift` provides adaptive light/dark colors via `NSColor` dynamic providers — no hardcoded hex values. The palette is intentionally monochromatic with a single accent; severity is communicated through restrained use of system orange and red.

Spacing uses a named scale (`DS.xs` = 4pt through `DS.xxl` = 48pt) rather than magic numbers.

## Session Persistence

Sessions are stored at:
```
~/Library/Application Support/WakeTrace/sessions.json
```

The store caps history at 90 sessions and deduplicates by sleep-start proximity (within 5 minutes).

## Entitlements

Sandboxing is disabled (`com.apple.security.app-sandbox = false`) because `log show` requires unsandboxed subprocess execution. No network or file-access entitlements are requested beyond what the system grants by default.

## License

MIT — see [LICENSE](../LICENSE).
