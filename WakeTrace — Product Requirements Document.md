# WakeTrace

**Product Requirements Document**

**Product:** WakeTrace  
**Platform:** macOS  
**Initial Version:** 1.0  
**Product Type:** Native macOS utility  
**Primary Interface:** Menu bar application + diagnostic window  
**Recommended Stack:** Swift, SwiftUI, AppKit where required  
**Distribution Target:** Direct download first; Mac App Store feasibility evaluated separately  
**Status:** Development specification

---

# 1. Product Summary

WakeTrace is a native macOS diagnostic utility that explains what a Mac did while it was supposed to be sleeping.

Its core promise is:

> **See exactly what your Mac did while the lid was closed.**

Instead of exposing users to raw power-management logs, process names, assertions, DarkWake messages, and Terminal commands, WakeTrace turns system activity into understandable sleep reports.

Example:

**Last night**

Mac asleep  
11:48 PM → 7:36 AM

Battery  
82% → 61%

**21% battery lost**

Normal for this Mac  
~2–4%

WakeTrace detected:

- 83 wake events
- 61 Bluetooth-related wake events
- 14 network maintenance events
- WhatsApp preventing sleep for 47 minutes
- unusually high background activity between 2:14–3:06 AM

WakeTrace should then answer:

**What happened?**

**What probably caused it?**

**Was it abnormal?**

**What can I do about it?**

WakeTrace is not intended to be a traditional battery monitor, system cleaner, Activity Monitor replacement, or generic optimization application.

Its initial purpose is specifically to make macOS sleep behaviour understandable.

---

# 2. Product Vision

WakeTrace should become:

> **The place you go when your Mac behaves strangely and you want to know why.**

The initial wedge is sleep diagnostics.

Future WakeTrace versions may explain:

- battery drain
- excessive heat
- unexpected fan activity
- high background CPU usage
- applications preventing sleep
- unexplained network usage
- abnormal wake behaviour
- background processes
- power assertions

Long term, WakeTrace can evolve toward:

> **Activity Monitor for humans.**

Instead of:

`mediaanalysisd — 87% CPU`

WakeTrace should eventually say:

> Photos is analysing your library.  
> This is currently responsible for most of your processor usage.  
> This activity is normally temporary.

However, these broader features are explicitly outside the initial MVP.

---

# 3. Problem

macOS exposes large amounts of diagnostic information but does a poor job translating that information for ordinary users.

When a user experiences unexpected sleep battery drain, they currently may need to investigate using tools such as:

- Console
- Activity Monitor
- Terminal
- `pmset`
- unified logs
- power assertions
- system reports
- Reddit/forum troubleshooting

Even technically capable users often need to correlate multiple sources manually.

The problem is therefore not that macOS lacks diagnostic information.

The problem is that:

**macOS provides data instead of answers.**

WakeTrace exists between those two layers.

---

# 4. Target Users

## 4.1 Primary

MacBook users experiencing:

- overnight battery drain
- battery drain while their laptop is in a bag
- unexpected warmth after closing the lid
- MacBook waking repeatedly
- apps preventing sleep
- unexplained background activity
- dramatically different sleep battery performance between days

Typical user question:

> Why did my Mac lose 25% battery overnight?

---

## 4.2 Secondary

Power users who currently inspect:

- `pmset`
- Activity Monitor
- Console
- system logs
- process activity

WakeTrace should save them from doing manual forensic work.

---

## 4.3 Future

Potential later audiences include:

- IT administrators
- Mac repair technicians
- developers
- enterprise support teams
- Apple support workflows

These are not MVP audiences.

---

# 5. Product Principles

## 5.1 Explain, don't dump

Never expose raw logs as the primary UI.

Bad:

> DarkWake from Normal Sleep [CDN] : due to EC.Bluetooth/Maintenance

Better:

> Bluetooth activity woke your Mac 37 times.

Advanced users may optionally inspect the underlying evidence.

---

## 5.2 Evidence before conclusions

WakeTrace must distinguish between:

- observation
- correlation
- likely cause
- confirmed cause

For example:

Bad:

> Spotify drained 18% of your battery.

Unless WakeTrace can prove it.

Better:

> Spotify remained active during 42 minutes of this sleep session and may have contributed to the increased battery usage.

Confidence should be represented internally.

---

## 5.3 Local-first

System diagnostics can contain sensitive information.

WakeTrace V1 should:

- analyse data locally
- store data locally
- require no WakeTrace account
- upload nothing by default
- contain no behavioural analytics requiring raw diagnostic logs

Any future cloud/AI feature must be explicitly opt-in.

---

## 5.4 Quiet by default

WakeTrace should not become another noisy menu-bar utility.

It should notify the user only when something meaningful happened.

Normal night:

No notification necessary.

Abnormal night:

> WakeTrace  
> Your Mac lost 18% while sleeping last night — about 5× your normal rate.

---

## 5.5 Low overhead

A diagnostic utility that causes battery drain defeats its own purpose.

WakeTrace must consume negligible:

- CPU
- memory
- network
- energy

It should primarily react to lifecycle events and perform heavier analysis after wake rather than continuously polling everything.

---

# 6. Primary User Journey

## First launch

User installs WakeTrace.

WakeTrace displays:

**Understand what your Mac does while it sleeps.**

WakeTrace can track:

- sleep duration
- wake activity
- battery loss
- sleep interruptions
- power assertions
- likely causes of unusual activity

Privacy message:

> WakeTrace analyses your Mac locally. Your system activity doesn't leave your Mac.

CTA:

**Start monitoring**

---

# 7. Onboarding

Onboarding should contain no more than three screens.

## Screen 1 — Value

**Know what happens after you close your Mac.**

WakeTrace turns confusing system events into understandable sleep reports.

---

## Screen 2 — Privacy

**Your Mac. Your data.**

Diagnostic analysis happens locally.

WakeTrace should clearly explain any macOS permissions it requests before macOS displays the permission prompt.

---

## Screen 3 — Ready

**You're ready.**

Close your Mac normally.

WakeTrace will prepare a report when you return.

CTA:

**Finish**

---

# 8. Core Product Loop

The primary WakeTrace loop is:

**Mac awake**

↓

Record baseline state

↓

**Mac enters sleep**

↓

Create SleepSession

↓

macOS performs sleep/wake activity

↓

**Mac returns**

↓

Collect relevant system evidence

↓

Analyse session

↓

Calculate anomaly level

↓

Generate human-readable report

↓

Notify user only if meaningful

↓

User opens WakeTrace

↓

Understand cause

↓

Potentially follow recommended action

↓

Future sessions establish whether behaviour improved

---

# 9. MVP Scope

WakeTrace 1.0 must support:

### Sleep session detection

Determine:

- sleep start
- final wake
- session duration
- intermediate wakes where detectable

### Battery tracking

Determine:

- battery at sleep
- battery at wake
- absolute percentage loss
- drain per hour
- charging state
- power source

### Wake-event collection

Capture/classify relevant:

- wake events
- DarkWake events
- maintenance wakes
- network-related wakes
- Bluetooth-related activity
- user-initiated wake
- lid wake
- power-related wake

### Power assertions

Identify applications/processes that:

- prevent idle sleep
- prevent system sleep
- request continuous activity where observable

### Session analysis

Generate:

- total sleep duration
- battery loss
- drain rate
- number of wakes
- wake categories
- suspicious processes
- timeline
- anomaly score

### Historical baseline

After sufficient sessions, calculate the user's normal:

- sleep drain/hour
- wakes/hour
- battery loss
- common wake sources

### Human-readable explanations

Convert evidence into plain-language findings.

### Notifications

Notify users about abnormal sessions.

### History

Allow users to inspect previous sleep reports.

---

# 10. Explicitly Out of Scope for V1

Do NOT include:

- generic Mac cleaning
- duplicate file removal
- RAM cleaning
- antivirus
- full Activity Monitor replacement
- network firewall
- fan control
- CPU throttling
- automated process killing
- automatic battery optimisation
- cloud accounts
- social features
- mobile app
- iCloud syncing
- AI chatbot
- remote Mac monitoring
- enterprise fleet management
- automatic execution of Terminal commands

Avoid feature creep.

WakeTrace V1 should win on one thing:

**sleep diagnostics.**

---

# 11. Menu Bar Experience

WakeTrace should run primarily as a menu-bar application.

Menu bar icon:

A minimal waveform / moon / pulse-style icon.

Clicking it displays:

---

**WakeTrace**

Last sleep

**7h 42m**

Battery  
83% → 79%

**4% lost · Normal**

No unusual activity detected.

`View report`

---

Current state:

**Awake**

Battery 76%

No application is currently preventing sleep.

---

Bottom actions:

History

Settings

Quit WakeTrace

---

When a problem exists:

**Sleep issue detected**

Battery  
91% → 68%

**23% lost · Abnormal**

Your Mac woke 126 times.

Bluetooth activity appears unusually high.

`View report`

---

# 12. Sleep Report

The report is WakeTrace's primary product surface.

## Header

**Tuesday Night**

October 6 → October 7

12:14 AM → 8:03 AM

7h 49m

---

## Battery card

### Battery

**82% → 64%**

18% consumed

**2.3% / hour**

Typical:

0.4% / hour

Indicator:

**5.7× higher than normal**

Status:

**Abnormal**

---

# 13. Diagnosis Summary

WakeTrace should immediately answer:

### What happened?

Example:

> Your Mac consumed significantly more battery than usual while sleeping.

### Why?

Example:

> It woke 94 times during the session. Most unusual activity was associated with Bluetooth and network maintenance.

### Biggest contributors

1. Bluetooth — 58 wake events
2. Network activity — 21 events
3. WhatsApp — prevented idle sleep for 37 minutes

The wording should always reflect confidence appropriately.

---

# 14. Timeline

Timeline example:

**12:14 AM**

Mac entered sleep

Battery: 82%

---

**12:37 AM**

Bluetooth activity

DarkWake

Duration: 18 sec

---

**12:44 AM**

Bluetooth activity

DarkWake

Duration: 14 sec

---

**1:21 AM**

Network maintenance

Duration: 42 sec

---

**2:03 AM**

WhatsApp prevented idle sleep

Duration: 37 min

---

**2:40 AM**

Mac returned to sleep

---

**8:03 AM**

Lid opened

Battery: 64%

Timeline entries should be grouped when repetitive.

Instead of displaying 63 individual Bluetooth events:

**Bluetooth activity**

63 wakes between 1:20–4:17 AM

`Show individual events`

---

# 15. Findings System

WakeTrace findings should follow a structured model.

Each finding contains:

```text
id
sessionID
category
severity
confidence
headline
explanation
evidence[]
recommendation?
```

Example:

```text
category:
bluetoothWake

severity:
high

confidence:
0.91

headline:
Bluetooth woke your Mac unusually often.

explanation:
WakeTrace detected 63 Bluetooth-associated wake events while your Mac was sleeping. Your recent average is 4.

recommendation:
Disconnect recently added Bluetooth accessories temporarily to see whether sleep behaviour improves.
```

---

# 16. Finding Categories

Initial categories:

```text
batteryDrain
frequentWake
bluetoothWake
networkWake
maintenanceWake
sleepAssertion
applicationActivity
shortSleep
chargingChanged
powerNapActivity
unknownWake
normalSession
```

Additional categories can be added later without changing the main data architecture.

---

# 17. Severity System

Four levels:

### Normal

Expected behaviour.

### Notice

Interesting but not necessarily problematic.

### Elevated

Meaningfully different from baseline.

### Critical

Likely user-visible impact such as severe battery drain.

Internal representation:

```text
0 normal
1 notice
2 elevated
3 critical
```

---

# 18. Confidence System

WakeTrace must avoid falsely blaming apps.

Every diagnosis should carry confidence:

```text
confirmed
high
medium
low
```

Internally:

```text
0.00–1.00
```

Suggested presentation rules:

**>0.9**

> X caused...

Only where causality is actually supported.

**0.70–0.89**

> X likely contributed...

**0.40–0.69**

> Activity associated with X was detected...

**<0.40**

Do not surface as a major diagnosis unless needed for advanced diagnostics.

---

# 19. Baseline Engine

WakeTrace becomes much more useful after learning normal behaviour.

For every Mac, maintain rolling baseline statistics.

Recommended initial window:

**previous 14 qualified sessions**

Qualified sleep session:

- ≥2 hours
- device not charging for majority of session
- no reboot interruption
- enough evidence successfully collected

Calculate:

```text
medianBatteryDrainPerHour
medianWakeEventsPerHour
medianSleepDuration
commonWakeCategories
medianAssertionDuration
```

Prefer median instead of mean to avoid extreme sessions distorting baseline.

---

# 20. Anomaly Detection

V1 should use deterministic statistical rules rather than machine learning.

Example battery anomaly:

```text
currentDrainRate / baselineDrainRate
```

Classification:

```text
<1.5x    Normal
1.5–2x   Notice
2–4x     Elevated
>4x      Critical
```

Absolute thresholds should also exist because a very low baseline can create exaggerated ratios.

Example:

```text
if drainRate > 2%/hour:
    atLeastElevated

if drainRate > 4%/hour:
    critical
```

Actual thresholds should be tuned using collected beta data.

---

# 21. Wake Anomaly Detection

Example:

```text
wakeRate = wakeCount / sleepHours
baselineWakeRate = historicalMedian
```

Flag when:

```text
wakeRate > baselineWakeRate * threshold
```

Also consider absolute number and category.

Example:

> Bluetooth wake activity was 8× higher than your usual level.

This is considerably more useful than:

> 46 DarkWake events detected.

---

# 22. Battery Session Model

Suggested model:

```swift
struct SleepSession {
    let id: UUID

    let sleepStartedAt: Date
    let finalWakeAt: Date

    let batteryAtSleep: Double
    let batteryAtWake: Double

    let wasChargingAtSleep: Bool
    let wasChargingAtWake: Bool

    let powerSourceAtSleep: PowerSource
    let powerSourceAtWake: PowerSource

    let wakeEvents: [WakeEvent]
    let assertions: [PowerAssertion]
    let findings: [Finding]

    let analysisVersion: Int
}
```

Computed:

```text
duration
batteryDelta
batteryDrainRate
wakeCount
wakeRate
anomalyScore
```

---

# 23. Wake Event Model

```swift
struct WakeEvent {
    let id: UUID
    let sessionID: UUID

    let timestamp: Date
    let endTimestamp: Date?

    let rawReason: String?
    let category: WakeCategory

    let processName: String?
    let bundleIdentifier: String?

    let source: EvidenceSource

    let confidence: Double
}
```

Categories:

```swift
enum WakeCategory {
    case bluetooth
    case network
    case maintenance
    case timer
    case lid
    case user
    case power
    case application
    case unknown
}
```

---

# 24. Power Assertion Model

```swift
struct PowerAssertion {
    let id: UUID

    let timestamp: Date
    let endTimestamp: Date?

    let processName: String?
    let pid: Int?

    let assertionType: String
    let reason: String?

    let duration: TimeInterval?
}
```

WakeTrace should associate assertions with apps where safely identifiable.

---

# 25. Evidence Model

Every conclusion should be traceable.

```swift
struct Evidence {
    let source: EvidenceSource
    let timestamp: Date
    let rawIdentifier: String?
    let normalizedValue: String
}
```

Possible sources:

```text
systemPowerEvent
unifiedLog
powerAssertion
batteryState
processInfo
ioregistry
userActivity
```

Keeping analysis separate from collection is important.

It allows WakeTrace's diagnosis engine to improve later without rewriting collection code.

---

# 26. Suggested Architecture

```text
WakeTrace
│
├── App
│   ├── MenuBar
│   ├── Dashboard
│   ├── Reports
│   ├── History
│   └── Settings
│
├── Monitoring
│   ├── SleepMonitor
│   ├── BatteryMonitor
│   ├── WakeMonitor
│   ├── AssertionMonitor
│   └── SystemEventCollector
│
├── Analysis
│   ├── SessionAnalyzer
│   ├── WakeClassifier
│   ├── BaselineEngine
│   ├── AnomalyDetector
│   └── FindingGenerator
│
├── Data
│   ├── Models
│   ├── Repository
│   └── Migration
│
├── System
│   ├── LogReader
│   ├── PowerReader
│   └── ProcessResolver
│
└── Notifications
    └── NotificationManager
```

---

# 27. Technical Direction

WakeTrace should primarily use public macOS APIs and documented system interfaces.

Apple's OSLog framework supports reading historical unified-log information, making it useful for post-wake analysis of system events.

`ProcessInfo` exposes useful system state including:

- system uptime
- thermal state
- Low Power Mode state
- power-state-change notifications

Apple also provides Endpoint Security for deeper process/system-event monitoring, but Endpoint Security involves a system extension and is substantially more invasive. It should **not be required for WakeTrace 1.0 unless testing proves the core product impossible without it.**

WakeTrace's preferred architecture should therefore be:

**event capture + post-wake system-log analysis**

rather than:

**continuous invasive process surveillance.**

---

# 28. Sleep Detection

WakeTrace needs reliable detection of:

```text
systemWillSleep
systemDidWake
```

Upon sleep:

1. record timestamp
2. record battery percentage
3. record charging state
4. record power source
5. persist session immediately
6. flush database
7. stop unnecessary work

Upon wake:

1. record timestamp
2. record battery state
3. wait briefly for macOS to stabilise if necessary
4. query relevant historical events for sleep window
5. classify events
6. run analysis
7. persist report
8. evaluate notification criteria

WakeTrace should be crash-safe.

A session opened before sleep should survive application termination or restart.

---

# 29. Analysis Pipeline

Recommended pipeline:

```text
Raw macOS evidence
        ↓
Normalization
        ↓
Event extraction
        ↓
Event classification
        ↓
Deduplication
        ↓
Session correlation
        ↓
Baseline comparison
        ↓
Finding generation
        ↓
Severity/confidence ranking
        ↓
Human-readable report
```

Do not couple UI directly to raw system data.

---

# 30. Wake Classification

Raw wake reason strings will vary across:

- macOS versions
- Mac models
- Intel vs Apple Silicon
- hardware configurations

Therefore classification should use a versionable rules engine.

Example:

```swift
protocol WakeClassificationRule {
    func match(event: RawSystemEvent) -> ClassificationResult?
}
```

Rules may match:

- subsystem
- category
- message tokens
- wake reason
- process
- hardware source

Classification rules should be unit-testable against captured fixtures.

---

# 31. Analysis Versioning

Each report must store:

```text
analysisVersion
```

Why:

WakeTrace's interpretation engine will improve over time.

Historical raw evidence may later be reanalysed using a better classifier.

Example:

```text
collectionVersion = 1
analysisVersion = 3
```

This separates:

**what happened**

from:

**how WakeTrace interpreted it.**

---

# 32. Storage

Recommended:

SwiftData or SQLite.

For a diagnostic application with potentially large event histories, SQLite gives greater explicit control.

Suggested tables:

```text
sleep_sessions
wake_events
power_assertions
findings
baseline_snapshots
system_metadata
app_settings
```

Raw logs should not be stored indefinitely.

Prefer extracting and storing only relevant normalized evidence.

Retention default:

**30 days**

Options:

- 7 days
- 30 days
- 90 days
- forever

Users should have:

**Delete all WakeTrace data**

---

# 33. Device Metadata

Record enough metadata to debug compatibility:

```text
Mac model
chip family
macOS version
WakeTrace version
battery health information where publicly available
```

Do not collect:

- serial number
- Apple ID
- personal filenames
- document contents
- browser history

unless absolutely required by a future feature.

---

# 34. Privacy Requirements

WakeTrace V1 must function completely offline.

No account.

No raw-log upload.

No cloud requirement.

No third-party AI.

No selling diagnostic data.

No hidden telemetry.

If product analytics are eventually added, they should collect product events such as:

```text
report_opened
history_opened
notification_clicked
```

rather than system-diagnostic content.

Diagnostic sharing should be explicit:

**Export diagnostic report**

and tell the user exactly what's being exported.

---

# 35. Notifications

Do not notify after every sleep.

Notification should trigger when:

```text
severity >= elevated
```

Example:

> **High sleep battery drain**
>
> Your Mac lost 19% over 7h 12m, about 4.8× your normal rate.
>
> WakeTrace found unusually frequent Bluetooth activity.

Click opens relevant report.

Optional setting:

**Notify after every sleep**

Default:

Off.

---

# 36. Report Status

Each session should have one high-level status:

```text
Normal
Interesting
Abnormal
Severe
Insufficient Data
```

Example card:

**Last night**

7h 18m

Battery  
89% → 85%

**4% lost**

✓ Normal

---

# 37. Recommendations

WakeTrace recommendations should be safe and reversible.

Example:

### Bluetooth activity is unusually high

Try temporarily disconnecting Bluetooth accessories before sleep tonight.

Then WakeTrace can compare tomorrow's result.

---

WakeTrace should avoid:

> Disable this daemon.

> Run this sudo command.

> Delete this system file.

No dangerous optimizations.

V1 should recommend actions instead of automatically modifying system settings.

---

# 38. Experiment Tracking

A compelling later V1.x capability:

**Try this tonight**

WakeTrace proposes:

> Disconnect your Bluetooth mouse before sleep.

User presses:

**I'll try this**

Next morning WakeTrace says:

> Battery drain improved from 2.7%/hour to 0.6%/hour.

This creates an extremely powerful troubleshooting loop.

Data structure:

```text
Experiment
id
findingID
startedAt
completedAt
recommendedAction
beforeMetrics
afterMetrics
result
```

This can be deferred until after core MVP if necessary.

---

# 39. Empty States

Before first session:

**No sleep reports yet**

Close your Mac normally.

WakeTrace will analyse the next sleep session.

---

After one normal session:

**Everything looks good**

Your Mac lost 2% during 7h 21m of sleep.

WakeTrace didn't detect anything unusual.

---

Before baseline exists:

> WakeTrace is still learning what's normal for this Mac.

Show:

**3 / 5 nights analysed**

Five qualifying sessions should be enough to show an initial personalized baseline.

---

# 40. History

History screen:

```text
OCTOBER

Today
7h 49m
18% ↓
Abnormal

Tuesday
6h 12m
3% ↓
Normal

Monday
8h 04m
2% ↓
Normal

Sunday
7h 57m
4% ↓
Normal
```

Graph:

**Sleep battery drain**

```text
% / hour

3 ┤                   ●
2 ┤
1 ┤       ●
0 ┤ ●  ●     ●  ●
```

The focus should remain interpretation, not chart overload.

---

# 41. Search / Filtering

Not required for initial MVP.

Later:

Filter reports by:

- normal
- abnormal
- battery drain
- Bluetooth
- network
- applications

---

# 42. Settings

## General

Launch WakeTrace at login

Show menu-bar icon

Check for updates

---

## Notifications

Notify me about:

☑ Unusual battery drain  
☑ Frequent wakes  
☑ Apps preventing sleep  
☐ Normal sleep reports

---

## Privacy

Data retention:

30 days

`Delete all local data`

`Export diagnostics`

---

## Advanced

Show raw diagnostic evidence

Enable verbose diagnostic logging

Reanalyse historical sessions

---

# 43. Accessibility

Support:

- VoiceOver
- keyboard navigation
- Reduce Motion
- increased text size where practical
- sufficient contrast
- system light/dark appearance

Do not rely solely on colour to indicate severity.

Use text/status icons as well.

---

# 44. macOS Design

WakeTrace should look native.

Use:

- SwiftUI
- SF Symbols
- system typography
- macOS materials sparingly
- native popovers
- native settings window
- native notifications

Avoid:

- Electron
- fake mobile-style navigation
- oversized dashboards
- excessive gradients
- gaming-style system-monitor visuals

The desired feeling:

> This could have shipped with macOS.

---

# 45. Performance Requirements

Idle CPU:

**approximately 0%**

Memory target:

**<100 MB**

Normal monitoring should not involve frequent polling.

Wake analysis may temporarily consume resources after waking but should complete efficiently.

WakeTrace itself must never intentionally prevent system sleep.

Add automated checks verifying WakeTrace owns no long-lived sleep-prevention assertion.

---

# 46. Reliability Requirements

WakeTrace must correctly handle:

- lid sleep
- manual sleep
- overnight sleep
- brief sleep
- charging during sleep
- charger disconnected during sleep
- Mac reboot
- WakeTrace crash
- WakeTrace update
- time-zone change
- daylight-saving change
- clock adjustment
- multiple short sleep cycles
- battery reaching critical levels

Incomplete sessions should not produce misleading diagnoses.

---

# 47. Session Qualification

A session may be marked:

```text
valid
partial
invalid
```

Example invalid cases:

- <10 minutes
- insufficient battery data
- reboot destroyed continuity
- diagnostic evidence unavailable

Partial report:

> WakeTrace couldn't access enough information to fully analyse this sleep session.

Never pretend analysis succeeded.

---

# 48. Supported macOS Versions

Development should initially target:

**Apple Silicon Macs**

Recommended minimum OS target should be chosen after API feasibility testing.

Ideal initial support:

- macOS 15+
- macOS 26+
- macOS 27+

However, the final minimum must be decided after validating:

- sleep notifications
- power data
- OSLog behaviour
- sandbox restrictions
- distribution model

Do not create compatibility complexity merely to support very old Macs during MVP.

---

# 49. Intel Macs

Treat Intel support as:

**best effort / post-MVP**

because sleep architecture and available signals may differ materially from modern Apple Silicon systems.

Prioritize:

M1  
M2  
M3  
M4  
newer Apple Silicon

first.

---

# 50. Distribution Strategy

Strong initial recommendation:

**Direct distribution outside the Mac App Store.**

Reasons:

WakeTrace is a system diagnostic utility and may require capabilities that are uncomfortable or impossible under strict sandboxing.

Direct distribution allows:

- notarized application
- Sparkle-style updates
- greater system visibility
- fewer sandbox constraints

The app must still:

- be Developer ID signed
- be notarized
- use documented APIs whenever possible
- clearly explain permissions

A separate App Store-compatible edition can be investigated later.

---

# 51. Permission Philosophy

WakeTrace should request the minimum permissions necessary.

Each request must have an explanation screen first.

Example:

**WakeTrace needs access to system diagnostics**

This allows WakeTrace to identify why your Mac woke while sleeping.

WakeTrace analyses this information locally.

`Continue`

Then invoke macOS permission flow.

Never dump multiple unexplained system prompts on first launch.

---

# 52. Technical Spike Before Full Development

Before building the complete UI, create an internal command-line / debug prototype.

Goal:

Take an arbitrary sleep interval:

```text
start timestamp
end timestamp
```

and output:

```json
{
  "batteryBefore": 82,
  "batteryAfter": 64,
  "wakeCount": 84,
  "wakeReasons": {},
  "assertions": [],
  "events": []
}
```

This proves the data pipeline.

This technical spike is the highest-priority development task.

Do not spend weeks designing UI before proving reliable sleep-event attribution.

---

# 53. Required Spike Experiments

Test on at least two Apple Silicon Macs if possible.

Create controlled cases:

### Test A

Normal lid-close sleep.

Expected:

WakeTrace identifies start/end correctly.

---

### Test B

Bluetooth accessories connected.

Compare wake-event patterns.

---

### Test C

Network activity/background sync.

Observe corresponding evidence.

---

### Test D

Application intentionally preventing idle sleep.

Verify assertion attribution.

---

### Test E

Charger connected/disconnected during session.

Verify battery diagnosis does not falsely label drain.

---

### Test F

Mac sleeps for only five minutes.

Ensure session is either correctly classified or ignored.

---

# 54. Development Phases

## Phase 0 — Technical feasibility

Deliverable:

CLI/debug analyser.

Requirements:

- identify sleep/wake boundary
- battery snapshots
- enumerate wake events
- retrieve relevant power/system evidence
- identify assertions where possible

**Gate:**

Do not proceed to polished product development until WakeTrace can correctly explain controlled test sessions.

---

## Phase 1 — Monitoring core

Build:

```text
SleepMonitor
BatteryMonitor
SessionRepository
WakeEventCollector
```

No fancy UI.

---

## Phase 2 — Classification

Build:

```text
WakeClassifier
AssertionParser
EventNormalizer
FindingGenerator
```

Create test fixtures from real sleep sessions.

---

## Phase 3 — Basic application

Build:

- menu bar
- onboarding
- last-session summary
- report view
- timeline
- settings

---

## Phase 4 — Baselines

Implement:

- qualifying sessions
- rolling baseline
- anomaly calculation
- personalized comparisons

---

## Phase 5 — Notifications

Add meaningful abnormal-session notifications.

---

## Phase 6 — Beta instrumentation

With explicit tester consent, allow users to export anonymized diagnostic bundles.

Use these to improve classification rules.

---

# 55. Suggested Repository Structure

```text
WakeTrace/
│
├── WakeTraceApp/
│
├── Features/
│   ├── MenuBar/
│   ├── Reports/
│   ├── History/
│   ├── Onboarding/
│   └── Settings/
│
├── Core/
│   ├── Monitoring/
│   ├── Analysis/
│   ├── Classification/
│   ├── Models/
│   ├── Storage/
│   └── System/
│
├── Resources/
│
├── Tests/
│   ├── MonitoringTests/
│   ├── ClassificationTests/
│   ├── AnalysisTests/
│   └── Fixtures/
│
└── WakeTrace.xcodeproj
```

---

# 56. Testing Strategy

Classification needs extensive fixture testing.

Example:

```swift
func testBluetoothDarkWakeClassification() {
    let event = fixture("bluetooth_darkwake_001")

    let result = classifier.classify(event)

    XCTAssertEqual(result.category, .bluetooth)
}
```

Store anonymized sample events from different:

- macOS versions
- MacBook models
- system configurations

Regression tests are essential because Apple's log wording may change between macOS releases.

---

# 57. Compatibility Layer

System parsing should never be scattered throughout the application.

Use:

```swift
protocol SystemEvidenceProvider
```

Implementations:

```text
MacOS15EvidenceProvider
MacOS26EvidenceProvider
MacOS27EvidenceProvider
```

only where behaviour actually diverges.

This protects the analysis engine from macOS changes.

---

# 58. Feature Flags

Important emerging features should be remotely unnecessary.

Use local feature flags:

```text
advancedAssertions
experimentalClassifier
diagnosticExport
experiments
```

No remote service is required.

---

# 59. Success Metrics

Primary:

### Diagnostic usefulness

Percentage of abnormal sessions where WakeTrace produces at least one useful high-confidence finding.

Target beta:

**>70%**

Target mature product:

**>90%**

---

### False blame rate

WakeTrace attributing a cause incorrectly.

Target:

**extremely low**

Accuracy matters more than having an answer for every session.

---

### Energy impact

WakeTrace's own energy usage should remain negligible.

---

### Report engagement

How often users open abnormal-session reports.

---

### Resolution

Later:

How often sleep behaviour improves after a WakeTrace recommendation.

This could become WakeTrace's strongest product metric.

---

# 60. MVP Acceptance Criteria

WakeTrace 1.0 is ready when:

1. A user can install and launch WakeTrace normally.

2. WakeTrace reliably detects major sleep sessions.

3. Battery before/after sleep is recorded accurately.

4. WakeTrace identifies intermediate wake activity where system evidence permits it.

5. Wake events are classified into useful categories.

6. Sleep-prevention assertions can be surfaced where available.

7. Reports provide a readable timeline.

8. Reports distinguish observations from likely causes.

9. Five or more sessions create a personalized baseline.

10. WakeTrace can identify abnormal battery drain relative to that baseline.

11. Abnormal sessions can trigger notifications.

12. Normal sessions don't create unnecessary notifications.

13. All core analysis works offline.

14. Users can delete their stored data.

15. WakeTrace itself does not meaningfully impact battery life or prevent sleep.

16. Unknown events are displayed honestly rather than falsely classified.

---

# 61. V1 User Stories

### WT-001

As a MacBook user, I want WakeTrace to notice when my Mac sleeps so I don't need to start monitoring manually.

### WT-002

As a user, I want to know how much battery disappeared while sleeping.

### WT-003

As a user, I want to know whether that battery loss is normal for my Mac.

### WT-004

As a user, I want to know how frequently my Mac woke while I wasn't using it.

### WT-005

As a user, I want those wakes grouped into understandable causes.

### WT-006

As a user, I want to know if an application prevented my Mac from sleeping.

### WT-007

As a user, I want a timeline so I can understand when abnormal activity occurred.

### WT-008

As a user, I want WakeTrace to notify me only when something unusual occurred.

### WT-009

As a privacy-conscious user, I want diagnostic information to remain on my Mac.

### WT-010

As an advanced user, I want access to the evidence underlying WakeTrace's conclusion.

---

# 62. Future Roadmap

## WakeTrace 1.1 — Troubleshooting

Add:

- guided experiments
- before/after comparison
- richer recommendations
- more wake classifiers

---

## WakeTrace 1.2 — Active diagnostics

Add:

**Why isn't my Mac sleeping right now?**

Live display:

> Chrome currently has an active power assertion.

---

## WakeTrace 1.5 — Battery

Expand beyond sleep:

> What's draining my battery?

Applications

Background jobs

Power trends

---

## WakeTrace 2.0 — System explanations

Potential modules:

### Heat

Why is my Mac hot?

### CPU

Why is my Mac suddenly slow?

### Network

What transferred data in the background?

### Storage activity

What is constantly writing to disk?

At this stage WakeTrace evolves toward:

> **Understand what your Mac is doing.**

---

# 63. Potential Premium Model

Do not paywall the fundamental answer after installing the product.

Possible model:

## Free

- current/last sleep report
- basic wake analysis
- battery drain analysis
- limited history

## WakeTrace Pro

Possible:

- unlimited history
- advanced baseline analysis
- guided experiments
- trends
- advanced diagnostics
- exported reports
- heat/CPU/network modules when available

Alternative:

Simple one-time purchase:

**$14.99–$24.99**

A focused Mac utility may benefit from a straightforward perpetual-license model more than another subscription.

Pricing should be validated after beta.

---

# 64. Positioning

Avoid:

**Advanced macOS power management monitoring software**

Prefer:

> **Find out what your Mac does while you sleep.**

Supporting copy:

> WakeTrace explains unexpected battery drain, repeated wakes and apps that keep your Mac awake.

---

# 65. Product Differentiation

WakeTrace does not win by collecting more telemetry than every system monitor.

It wins by creating this transformation:

```text
SYSTEM DATA
↓
EVIDENCE
↓
CORRELATION
↓
CONTEXT
↓
EXPLANATION
```

The moat can eventually become:

- classification rules
- compatibility knowledge across Macs/macOS
- personalized baselines
- diagnosis quality
- historical comparisons
- troubleshooting experiments

The valuable intellectual property is therefore primarily the **diagnostic engine**, not the interface.

---

# 66. Product Rule

One rule should guide every WakeTrace feature:

> **Never show the user system information without answering why they should care.**

Instead of:

**83 wake events**

Say:

**Your Mac woke 83 times — about 7× more frequently than normal. Most were associated with Bluetooth.**

Instead of:

**PreventUserIdleSystemSleep = 1**

Say:

**Chrome is currently preventing your Mac from entering normal idle sleep.**

Instead of:

**Battery delta: -17**

Say:

**Your Mac lost 17% while sleeping. It normally loses around 3% over the same period.**

That translation layer is WakeTrace.

---

# 67. First Development Milestone

Do not begin with the final application.

Create:

**WakeTrace Lab**

An internal diagnostic executable.

Input:

```text
sleep start
wake end
```

Output:

```text
Sleep: 7h 41m
Battery: 87 → 69 (-18%)

Wake events: 97

Bluetooth: 61
Network: 17
Maintenance: 11
Unknown: 8

Power assertions:
WhatsApp — 42m
sharingd — 8m

Assessment:
SEVERE BATTERY DRAIN

Likely contributors:
1. Frequent Bluetooth wakes
2. WhatsApp sleep assertion
```

Once WakeTrace Lab can repeatedly produce trustworthy output across real Macs, build the beautiful application around it.

**The diagnostic engine is the product. The UI is how users experience it.**

---

# 68. Definition of Product Success

WakeTrace succeeds when somebody opens their Mac in the morning, sees their battery unexpectedly low, clicks one icon and understands:

**what happened,**

**when it happened,**

**what likely caused it,**

and

**what they can reasonably do next**

without opening Terminal, Console, Activity Monitor, Reddit, or Google.