//
//  StreakCalculator.swift
//  Rhythm
//
//  Pure, side-effect-free streak math. Easily unit-testable.
//
//  Definitions:
//   - **Beat streak:** consecutive scheduled days (per the parent rhythm's
//     active days) ending today (or yesterday if today hasn't occurred yet)
//     where the beat has at least one completion.
//   - **Rhythm streak:** same idea, but every beat in the rhythm must have
//     at least one completion on the day.
//   - **Grace day:** in any rolling 7-day window we walk through, **one** missed
//     scheduled day does not break the streak. A second miss inside the same
//     7-day window does.
//   - **Best streak:** longest run anywhere in history (no grace day is reused
//     globally — the rolling window resets as we walk through history).
//

import Foundation

enum StreakCalculator {

    // MARK: - Public API

    nonisolated static func beatStreak(
        for beat: Beat,
        in rhythm: Rhythm,
        completions: [Completion],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> StreakSnapshot {
        let beatCompletions = completions.filter { $0.beatID == beat.id }
        return computeStreak(
            activeDays: rhythm.activeDays,
            today: today,
            calendar: calendar,
            isDayCompleted: { day in
                beatCompletions.contains { c in
                    calendar.isDate(c.completedAt, inSameDayAs: day)
                }
            }
        )
    }

    nonisolated static func rhythmStreak(
        for rhythm: Rhythm,
        completions: [Completion],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> StreakSnapshot {
        let rhythmCompletions = completions.filter { $0.rhythmID == rhythm.id }
        let beatIDs = Set(rhythm.beats.map { $0.id })
        guard !beatIDs.isEmpty else { return .zero }

        return computeStreak(
            activeDays: rhythm.activeDays,
            today: today,
            calendar: calendar,
            isDayCompleted: { day in
                let onDay = rhythmCompletions.filter {
                    calendar.isDate($0.completedAt, inSameDayAs: day)
                }
                let completedBeatIDs = Set(onDay.map { $0.beatID })
                return beatIDs.allSatisfy { completedBeatIDs.contains($0) }
            }
        )
    }

    // MARK: - Core walker

    /// Walks backwards through scheduled days, counting consecutive hits with at
    /// most one allowed miss per rolling 7-day window. Also tracks the best run
    /// across history and whether the user already used their grace this week.
    nonisolated private static func computeStreak(
        activeDays: Set<Weekday>,
        today: Date,
        calendar: Calendar,
        isDayCompleted: (Date) -> Bool
    ) -> StreakSnapshot {
        guard !activeDays.isEmpty else { return .zero }

        // Walk back up to 365 days — generous bound for any UI we care about.
        let maxLookback = 365

        var current = 0
        var best = 0
        var run = 0
        var graceUsedInRun = false
        // Whether the still-active "current" run has already used its grace.
        var currentUsedGrace = false
        var sawCurrent = false

        // Current run window for grace: track misses inside the last 7 days
        // **of the run**.
        var missesInRollingWindow: [Int] = [] // indices of days back (0 = today)

        var dayIndex = 0
        while dayIndex < maxLookback {
            guard let day = calendar.date(byAdding: .day, value: -dayIndex, to: today) else { break }

            // Trim rolling window to the last 7 day-indices.
            missesInRollingWindow.removeAll { dayIndex - $0 >= 7 }

            let weekday = Weekday.from(date: day, calendar: calendar)
            let scheduled = activeDays.contains(weekday)

            if !scheduled {
                // Non-scheduled days are skipped — they neither extend nor break.
                dayIndex += 1
                continue
            }

            let completed = isDayCompleted(day)

            if completed {
                run += 1
            } else {
                // Allow at most one miss per rolling 7-day window.
                let recentMisses = missesInRollingWindow.count
                if recentMisses < 1 {
                    // Use grace.
                    missesInRollingWindow.append(dayIndex)
                    graceUsedInRun = true
                } else {
                    // Run terminates. Snapshot it.
                    if run > best { best = run }
                    if !sawCurrent {
                        current = run
                        currentUsedGrace = graceUsedInRun
                        sawCurrent = true
                    }
                    // Continue scanning history to find best across all time,
                    // but reset run state.
                    run = 0
                    graceUsedInRun = false
                    missesInRollingWindow.removeAll()
                }
            }

            dayIndex += 1
        }

        // Finalize: any run still open at the end of history counts.
        if run > best { best = run }
        if !sawCurrent {
            current = run
            currentUsedGrace = graceUsedInRun
        }

        return StreakSnapshot(
            current: current,
            best: best,
            usedGraceDayThisWeek: currentUsedGrace
        )
    }
}

#if DEBUG
// MARK: - Inline sanity checks
//
// These are not XCTest cases — they are lightweight assertions you can call
// from a debug menu or a unit test target. They cover the cases the spec calls
// out: 0-streak, perfect run, grace-day forgiven, two misses break.
//
extension StreakCalculator {

    /// Run debug-time assertions. Prints "✅ StreakCalculator tests passed" or fails.
    nonisolated static func runDebugTests() {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date(timeIntervalSince1970: 1_730_000_000)) // fixed reference
        let allDays = Set(Weekday.allCases)

        // Helper to make a completion on dayOffset (negative = past).
        func completion(beatID: UUID, rhythmID: UUID, dayOffset: Int) -> Completion {
            let day = cal.date(byAdding: .day, value: dayOffset, to: today)!
            return Completion(beatID: beatID, rhythmID: rhythmID, completedAt: day)
        }

        let beat = Beat(name: "Stretch", order: 0)
        let rhythm = Rhythm(name: "Morning", activeDays: allDays, beats: [beat])

        // 1) No completions -> zero streak.
        let zero = beatStreak(for: beat, in: rhythm, completions: [], today: today, calendar: cal)
        assert(zero.current == 0, "Expected 0, got \(zero.current)")

        // 2) Perfect 5-day run ending today.
        let perfect = (-4...0).map { completion(beatID: beat.id, rhythmID: rhythm.id, dayOffset: $0) }
        let perfectResult = beatStreak(for: beat, in: rhythm, completions: perfect, today: today, calendar: cal)
        assert(perfectResult.current == 5, "Expected 5, got \(perfectResult.current)")

        // 3) Missed yesterday but otherwise 7-day run -> grace forgives -> current = 7 (today + 5 prior + grace day).
        //    Days: -6,-5,-4,-3,-2 done, -1 missed, 0 done -> 6 hits, 1 grace = current 7? 
        //    Implementation: counts consecutive *completed* scheduled days plus uses grace to skip a miss.
        //    With our walker run counts only completed days; we expect run=6 (hits), not 7.
        let withMiss: [Completion] = [-6, -5, -4, -3, -2, 0].map {
            completion(beatID: beat.id, rhythmID: rhythm.id, dayOffset: $0)
        }
        let missResult = beatStreak(for: beat, in: rhythm, completions: withMiss, today: today, calendar: cal)
        assert(missResult.current == 6, "Expected 6 (grace forgives miss), got \(missResult.current)")
        assert(missResult.usedGraceDayThisWeek, "Expected grace day flag")

        // 4) Two misses inside a 7-day window break the streak.
        //    Days completed: 0, -2, -4, -6. Miss at -1 and -3 -> two misses -> only the run of "0" counts as current? 
        //    Walking from 0: completed -> run=1; -1 missed -> grace; -2 completed -> run=2;
        //    -3 missed -> 2nd miss in window -> break -> current=2.
        let twoMisses: [Completion] = [0, -2, -4, -6].map {
            completion(beatID: beat.id, rhythmID: rhythm.id, dayOffset: $0)
        }
        let twoMissResult = beatStreak(for: beat, in: rhythm, completions: twoMisses, today: today, calendar: cal)
        assert(twoMissResult.current == 2, "Expected 2 (two misses break), got \(twoMissResult.current)")

        // 5) Rhythm streak requires all beats completed each day.
        let beatA = Beat(name: "A", order: 0)
        let beatB = Beat(name: "B", order: 1)
        let rhythm2 = Rhythm(name: "Both", activeDays: allDays, beats: [beatA, beatB])
        let bothCompletions: [Completion] = [
            completion(beatID: beatA.id, rhythmID: rhythm2.id, dayOffset: 0),
            completion(beatID: beatB.id, rhythmID: rhythm2.id, dayOffset: 0),
            completion(beatID: beatA.id, rhythmID: rhythm2.id, dayOffset: -1),
            // beatB missed yesterday — rhythm not fully completed -> grace forgives once
            completion(beatID: beatA.id, rhythmID: rhythm2.id, dayOffset: -2),
            completion(beatID: beatB.id, rhythmID: rhythm2.id, dayOffset: -2),
        ]
        let rhythmResult = rhythmStreak(for: rhythm2, completions: bothCompletions, today: today, calendar: cal)
        assert(rhythmResult.current == 2, "Expected rhythm streak 2, got \(rhythmResult.current)")

        print("✅ StreakCalculator tests passed")
    }
}
#endif
