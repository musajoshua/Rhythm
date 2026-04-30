# Rhythm

> *Find your daily flow.*
> A personal habit and routine tracker built around **rhythms** (routines), **beats** (habits), and short **reflections** — calmer than a streak grid, smarter than a checklist.

EPITA — *iOS and Swift Fundamentals* group project.

---

## 1. Business case

### Problem
Existing habit trackers (Streaks, Habitify, Way of Life…) treat habits as isolated checkboxes on a grid. They miss the bigger picture: **most habits live inside routines.** People don't just "meditate" — they meditate *as part of their morning rhythm*. When the routine breaks, every habit in it tends to collapse together.

### Target users
- **Primary:** Adults 22–40 building or rebuilding personal routines.
- **Secondary:** Students managing study + wellness routines.
- **Tertiary:** Wellness-curious users who bounced off rigid trackers.

### Value proposition
Rhythm tracks **routines, not just habits**. You build a *rhythm* (e.g. Morning Reset, Wind-Down), each containing a sequence of *beats*. The app then:
1. Visualises today as an editorial dashboard rather than a checklist.
2. Tracks streaks at both the **beat level and the rhythm level** — but surfaces *momentum* (Low / Building / Strong / Locked In) as the headline metric, so a single missed day doesn't feel like failure.
3. Lets the user write a short **reflection** for each rhythm each day.
4. Uses **on-device Apple Intelligence** as a personal coach — surfacing patterns and writing weekly summaries grounded in the user's own data and reflections.

### Differentiation
| Typical habit trackers | Rhythm |
|---|---|
| Grid of checkboxes | Editorial cards in a calm cream/dark theme |
| Habits are isolated | Habits live inside named rhythms |
| Streaks per habit only | Streaks per beat **and** per rhythm — plus weekly **momentum** |
| Static reminders | AI Coach grounds suggestions in your data and reflections |
| Cloud sync, accounts | Fully on-device, private by default |

### Monetisation (Freemium + Subscription)
- **Free:** up to 2 rhythms, up to 8 beats, basic momentum, manual logging.
- **Pro (€2.99 / month or €19.99 / year):** unlimited rhythms and beats, AI Coach insights, weekly AI reflections, advanced charts, iCloud backup (future), Siri shortcuts.

A static paywall card lives in **Settings → Rhythm Pro**. Payments are not implemented in v1.

---

## 2. Constraints (project rules)

- Swift only.
- Apple-native frameworks only — SwiftUI, Foundation, FoundationModels (Apple Intelligence), UserNotifications, AppIntents-ready.
- **No external libraries** (no SPM, no CocoaPods, no Carthage).
- Persistence: native — local JSON via `Codable` in the Documents directory.
- Architecture: **MVVM** with a Services layer.
- 5 screens (spec asked for 3 minimum) with clear navigation.
- Stability: defensive coding, empty states everywhere, no force unwraps.
- Target: iOS 26+ (required for Foundation Models). iPhone, portrait.

---

## 3. Architecture

```
Rhythm/
├── App/
│   ├── RhythmApp.swift          @main, root scene
│   ├── RootView.swift           Onboarding gate ↔ tab shell
│   └── RootTabView.swift        Today · Rhythms · Insights · Settings
├── Models/
│   ├── Rhythm                   notes, period, iconName, reminderTime, beats, activeDays
│   ├── Beat                     name, symbol, duration, isRequired, details
│   ├── Completion               beat/rhythm/day stamps
│   ├── DailyReflection          per-(rhythmID, day) note
│   ├── Weekday, Streak          enums + value types
│   ├── RhythmPeriod             Morning / Midday / Evening / Night / Anytime
│   ├── MomentumLevel            Low / Building / Strong / Locked In
│   └── RhythmTemplate           starter rhythms used by onboarding
├── ViewModels/                  @Observable, @MainActor
│   ├── TodayViewModel
│   ├── RhythmsViewModel
│   ├── RhythmEditorViewModel
│   ├── InsightsViewModel
│   ├── SettingsViewModel
│   └── OnboardingViewModel
├── Views/
│   ├── Today/        TodayView, RhythmCard, MomentumCard
│   ├── Rhythms/      RhythmsView, RhythmDetailView (with reflection editor)
│   ├── Editor/       RhythmEditorView (Rhythm2-style form)
│   ├── Insights/     InsightsView, AICoachCard, WeeklyChartView
│   ├── Settings/     SettingsView
│   ├── Onboarding/   OnboardingView (intro slideshow + template picker)
│   └── Components/   BeatDot, BeatRow, StreakChip, StatTile,
│                     EmptyStateView, SectionHeader, PeriodChip,
│                     ProgressRing, PrimaryActionButton, DayPip
├── Services/
│   ├── PersistenceService    Codable + JSON file I/O, debounced atomic save
│   ├── StreakCalculator      Pure functions, grace-day algorithm + DEBUG tests
│   ├── AICoachService        FoundationModels wrapper, streaming, fallback
│   ├── NotificationService   UNUserNotificationCenter wrapper
│   └── SampleData            Demo seed used by previews and the debug menu
└── Theme/
    ├── Theme                 Colors (warm/dark adaptive), spacing, motion, period palette
    ├── Typography            Serif display + system rounded scale
    └── View+Card             rhythmCard() modifier — 24pt rounded surface + soft shadow
```

### MVVM rules
- **Models** are plain `Codable` `Sendable` `nonisolated` structs. No logic beyond convenience.
- **ViewModels** are `@Observable @MainActor` classes. They own state, expose intents, call services. They never import SwiftUI types beyond `Color` (we use raw hex strings instead).
- **Views** are SwiftUI structs. Pure layout + binding.
- **Services** are injected into ViewModels via initializer (defaulting to `.shared`).

---

## 4. Visual language

The look is **Apple Health × Apple Journal** — calm, editorial, low-saturation.

- **Palette:** warm cream background (`#FAF7F2` light / `#101114` dark), muted sage accent (`#6B8068`), and per-period tints — Morning amber, Midday gold, Evening blue, Night indigo, Anytime grey.
- **Typography:** serif `display` font for hero headings (greeting, screen title); system **rounded** for everything else.
- **Cards:** 24pt rounded surfaces with a soft drop shadow via the shared `rhythmCard()` modifier.
- **Hero metric:** **Momentum** (instead of a noisy animated wave). Streaks remain in the data layer and surface as small flame chips on Today cards.
- **Charts:** custom `TrendBar` shapes — no Charts framework dependency, so the rendering matches the rest of the design system.
- **Periods:** every rhythm carries a `RhythmPeriod`. The home screen orders cards by period and tints icons / chips with the period palette.

---

## 5. Screens

1. **Today** — editorial top bar (serif greeting + circular `+` button), `MomentumCard` hero (progress ring + 7 day-pips + level + description), period-ordered list of `RhythmCard`s. Tapping a card pushes the detail view.
2. **Rhythms** — list of every rhythm with circular icon, period chip, weekday dots, and reminder time.
3. **Rhythm Detail** — hero card (icon circle + period chip + serif title + notes), inline 3-stat row (`Today X/Y` · `Progress %` · `Reminder HH:MM`), tap-to-toggle beat rows with optional details, and a **Reflection** TextEditor with auto-save + "Saved at HH:MM" stamp.
4. **Rhythm Editor** *(modal)* — name, notes, period picker, icon scroller, daily-reminder toggle + time, beats list with required/optional toggle and details, delete button when editing.
5. **Insights** — large hero progress ring + momentum description, custom 7-day TrendBar chart, "Strongest rhythm" card, three stat tiles, AI weekly reflection + AI single suggestion (streamed), recent reflections list, per-rhythm breakdown.
6. **Settings** — Rhythm Pro paywall preview, master notifications toggle, debug actions (insert sample week, run streak self-tests in DEBUG), about, two-step **Reset all data**.

Plus an **Onboarding** flow on first launch: two intro pages + a starter-template picker with Morning Reset pre-selected.

---

## 6. Apple Intelligence integration

`AICoachService` wraps Apple's on-device **Foundation Models** framework (`import FoundationModels`).

- Generates the **weekly reflection** with `LanguageModelSession` + `streamResponse(to:)`. The response is rendered token-by-token as it arrives.
- Generates a one-sentence **"one thing to try this week"** suggestion in parallel.
- Reads `SystemLanguageModel.default.availability` and falls back gracefully to a rule-based summary when Apple Intelligence is unavailable. The card never goes empty.
- **Reflection-aware prompts.** The `WeeklySummary` passed to the model includes up to 3 recent user reflections; the system prompt invites the coach to echo a short phrase from them.
- Rate-limits the **Refresh** button to once per 30 seconds.
- Caches the latest reflection + suggestion per ISO week in `UserDefaults`. The cache is invalidated when the user disables Apple Intelligence so the body of the card always matches the footer.

All processing is on-device — no network, no API keys.

---

## 7. Streak algorithm (grace day)

`StreakCalculator` is a set of pure, testable functions:

- **Beat streak:** consecutive scheduled days (by the parent rhythm's active days) where the beat has at least one completion.
- **Rhythm streak:** same, but **every required beat** in the rhythm must have at least one completion that day. Optional beats don't count toward "complete".
- **Grace day:** in any rolling 7-day window of the run, **one** missed scheduled day is forgiven. A second miss inside the same window breaks the streak.
- **Best streak:** the longest run anywhere in history.

The 5 cases above are validated by **Settings → Debug → Run streak self-tests** (DEBUG builds only) — the assertions run in-place and print `✅ StreakCalculator tests passed` to the Xcode console on success.

---

## 8. Persistence

`PersistenceService` keeps the entire `RhythmDatabase` in memory (rhythms + completions + reflections) and writes the whole document atomically to `Documents/rhythm_db.json`. Saves are **debounced** (0.3s) so rapid mutations coalesce into a single file write. Decoding failures are non-fatal — the app starts with `.empty` and logs.

`Beat`, `Rhythm` and `RhythmDatabase` all carry **tolerant** `Codable` conformance: payloads from earlier schema versions (with `startHour/startMinute`, `accentHex`, `notificationsEnabled`, no `reflections`) load cleanly with sensible defaults.

---

## 9. Notifications

`NotificationService` wraps `UNUserNotificationCenter`. Each rhythm has its own optional `reminderTime`; toggling the **Daily reminder** in the editor schedules one repeating `UNCalendarNotificationTrigger` per active day at that time, and prompts for OS permission when needed. The master toggle in **Settings → Reminders** controls the global permission.

---

## 10. Running locally

1. Open `Rhythm.xcodeproj` in **Xcode 26+**.
2. Pick an **iPhone iOS 26+** simulator or device.
3. Run.
4. First launch shows onboarding. Pick a starter template or skip.
5. To get a populated demo on demand: **Settings → Debug → Insert sample week**. Three rhythms, a week of completions, and three sample reflections.

For Apple Intelligence: enable Apple Intelligence on the simulator/device in System Settings. The app falls back to rule-based copy when AI is off.

---

## 11. Demo plan (10 minutes)

| Minutes | Beats |
|---|---|
| 0–2 | Business pitch — problem, users, why Rhythm is different, monetisation. |
| 2–6 | Live demo. *Insert sample week*. Today → tap a card → toggle a beat → write a reflection → switch to Insights → trigger AI reflection (token streaming visible) → toggle Apple Intelligence to show the rule-based fallback. |
| 6–9 | Technical: MVVM diagram, persistence + tolerant Codable, FoundationModels streaming snippet, grace-day algorithm. |
| 9–10 | Wrap. Each member names what they owned. Roadmap one-liner. |

A backup screen recording is recommended in case the live demo or model call hiccups.

---

## 12. Out of scope (v1)

- Accounts, login, cloud sync.
- Real in-app purchase (paywall is a static card).
- Apple Watch companion (roadmap).
- Widgets (roadmap).
- Localisation (English only).
- Per-rhythm reflection history view (Insights aggregates across rhythms).

---

## 13. Team contributions

| Member | Owned |
|---|---|
| _name_ | Models, persistence, streak algorithm, sample data |
| _name_ | Today + Rhythms + Editor + onboarding |
| _name_ | Insights, AI Coach integration, fallback path |
| _name_ | Theme, components, animations, settings + notifications |
| _name_ | Pitch, README, presentation |

(Fill in before submission.)

---

*Build deliberately. When in doubt, choose the calmer, simpler option — that is what Rhythm is.*
