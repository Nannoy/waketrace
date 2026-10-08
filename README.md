# WakeTrace

A native macOS menu bar app that tells you what your Mac did while it was sleeping — battery drain, wake events, and why.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-blue)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-first-black)

---

## Why

Every morning you open your MacBook to find 20% less battery than you left it with. macOS gives you nothing. WakeTrace reads the system logs your Mac already writes, classifies every wake event, and surfaces a plain-English report — no account, no cloud, no telemetry.

## Features

- **Sleep report** — duration, battery drain rate vs your personal baseline, classified wake events
- **Wake timeline** — every dark wake and full wake visualised across the night
- **Findings** — ranked, actionable insights (Bluetooth storms, rogue sleep assertions, Power Nap activity)
- **History** — 7-day and rolling session list with mini stats per night
- **Notifications** — optional post-wake alert when something unusual is detected
- **Purely on-device** — reads `powerd` log entries and IOKit battery state; nothing leaves your Mac

## Requirements

| | |
|---|---|
| macOS | 14.0 Sonoma or later |
| Architecture | Apple Silicon (arm64) |
| Xcode | 15 or later |
| Tools | [xcodegen](https://github.com/yonaskolb/XcodeGen) |

## Getting Started

```bash
# Clone
git clone https://github.com/your-username/wakatrace.git
cd wakatrace

# Build the macOS app
cd WakeTrace
xcodegen generate
xcodebuild -scheme WakeTrace -destination 'platform=macOS' build

# Or run the CLI diagnostic tool
cd ../WakeLab
swift run WakeLab
```

Open `WakeTrace.app` from Xcode's DerivedData or directly from Finder. The waveform icon appears in your menu bar — no Dock icon by design.

## Project Structure

```
wakatrace/
├── WakeTrace/          # macOS menu bar app (SwiftUI)
│   └── WakeTrace/
│       ├── App/            # Entry point, scene definitions
│       ├── Core/           # Data layer: log reading, classification, analysis
│       ├── DesignSystem/   # Colors, spacing, shared components
│       ├── Features/       # UI screens (MenuBar, Report, History, Settings…)
│       ├── Models/         # UI-layer data types
│       └── State/          # AppState, SessionStore, MockData
└── WakeLab/            # Swift Package CLI — standalone diagnostic tool
    └── Sources/WakeLab/
        ├── Collectors/     # LogReader, BatteryReader
        ├── Classifier/     # WakeClassifier
        ├── Analyzer/       # SessionBuilder, SessionAnalyzer
        └── Models/         # Core data models
```

See [`WakeLab/README.md`](WakeLab/README.md) for CLI usage and [`WakeTrace/README.md`](WakeTrace/README.md) for app architecture details.

## How It Works

1. **At sleep** — `SleepMonitor` catches `NSWorkspace.willSleepNotification` and snapshots the battery via IOKit
2. **At wake** — queries `log show` with a tight `powerd` predicate (runs in <2 s) for the sleep window
3. **Classification** — `WakeClassifier` maps Apple Silicon wake-reason strings to categories (Bluetooth, Maintenance, Network, Power, Lid, etc.)
4. **Analysis** — `SessionAnalyzer` produces ranked `Finding` items with severity, headline, and recommendation
5. **Baseline** — `BaselineEngine` computes a rolling 14-session median so anomaly detection is personalised
6. **Persist** — sessions are stored as JSON in `~/Library/Application Support/WakeTrace/`

## Privacy

WakeTrace has no network entitlements. It reads two on-device sources:

| Source | What | How |
|--------|------|-----|
| Unified Log | `powerd` sleep/wake entries | `log show` subprocess |
| IOKit | Battery percentage, charging state | `IOPSCopyPowerSourcesInfo` |

No data is transmitted, stored in iCloud, or shared with any third party.

## Contributing

Issues and pull requests are welcome. Please open an issue before starting large changes.

```bash
# Run the CLI tool against last night's sleep
cd WakeLab
swift run WakeLab

# Run with explicit window
swift run WakeLab --start "2026-10-07 00:00:00" --end "2026-10-07 09:00:00"

# JSON output
swift run WakeLab --format json
```

## License

MIT — see [LICENSE](LICENSE).
