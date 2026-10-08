# WakeLab

A Swift Package CLI that reads your Mac's sleep/wake history from the system log and produces a plain-English diagnostic report. WakeLab is the data-layer foundation of the [WakeTrace](../WakeTrace) macOS app and can also be used standalone from the terminal.

## Usage

```bash
cd WakeLab

# Auto-detect the most recent sleep session
swift run WakeLab

# Explicit date range
swift run WakeLab --start "2026-10-07 00:00:00" --end "2026-10-07 09:00:00"

# JSON output (pipe-friendly)
swift run WakeLab --format json

# Last 12 hours
swift run WakeLab --start "$(date -v-12H '+%Y-%m-%d %H:%M:%S')"
```

### Example Output

```
WakeLab — Sleep Session Report
────────────────────────────────────────────────────────────────
Session:  2026-10-07 00:14 → 08:03  (7h 49m)
Battery:  83% → 61%  (drain: 2.81%/hr)

Wake Events: 55 total
  Bluetooth   20
  Maintenance 31
  Power        2
  Lid          1
  Timer        1

Findings:
  [CRITICAL] Severe battery drain while sleeping.
    Your Mac lost 22% over 7h 49m (2.8%/hr). A sleeping Mac typically
    drains under 1%/hr.

  [ELEVATED]  Bluetooth woke your Mac 20 times.
    20 of 55 wake events (36%) were linked to Bluetooth activity.
    → Disconnect Bluetooth accessories before sleep to test.

  [NORMAL]    31 maintenance wakes were detected.
    macOS performed Power Nap tasks and scheduled maintenance.
```

## Requirements

- macOS 14+, Apple Silicon
- Swift 5.9+ / Xcode 15+

## Build

```bash
swift build
swift test
.build/debug/WakeLab --format json | jq '.findings[].headline'
```

## Architecture

```
Sources/WakeLab/
├── main.swift              # CLI entry point, argument parsing
├── Models/
│   └── Models.swift        # WakeCategory, WakeEvent, SleepSession, Finding, PowerAssertion
├── Collectors/
│   ├── LogReader.swift     # log show wrapper, compact-format parser, assertion parser
│   └── BatteryReader.swift # IOKit power source reader
├── Classifier/
│   └── WakeClassifier.swift # Rule-based wake reason → WakeCategory mapper
└── Analyzer/
    └── SessionAnalyzer.swift # SessionBuilder + SessionAnalyzer → [Finding]
```

### Key Technical Choices

**`log show` over `pmset -g log`**  
`pmset -g log` produces thousands of lines and can take >2 minutes. WakeLab uses `log show` with a tight predicate targeting only `powerd`'s `sleepWake` category — this returns in under 2 seconds for a 24-hour window.

**Apple Silicon wake reason strings**  
Intel Macs used strings like `EC.Bluetooth`. Apple Silicon uses a unified-log format:  
`DarkWake from Deep Idle [CDNP] : due to smc.sysState.Wake wifibt SMC.OutboxNotEmpty bluetooth-pcie/`  
The classifier is written for M-series strings.

**`vm.darkwake_mode` filtering**  
These internal state-transition lines contain "darkwake" but are not wake events. They are explicitly excluded before classification.

## License

MIT — see [LICENSE](../LICENSE).
