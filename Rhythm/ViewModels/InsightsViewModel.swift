//
//  InsightsViewModel.swift
//  Rhythm
//

import Foundation
import Observation

@Observable
@MainActor
final class InsightsViewModel {
    private let persistence: PersistenceService
    private let aiCoach: AICoachService
    private let calendar: Calendar

    var reflectionText: String?
    var suggestionText: String?
    var isGenerating: Bool = false
    var lastError: String?
    private var lastGenerationAt: Date?

    private let rateLimitSeconds: TimeInterval = 30

    init(persistence: PersistenceService? = nil,
         aiCoach: AICoachService? = nil,
         calendar: Calendar = .current) {
        let resolvedPersistence = persistence ?? PersistenceService.shared
        let resolvedCoach = aiCoach ?? AICoachService.shared
        self.persistence = resolvedPersistence
        self.aiCoach = resolvedCoach
        self.calendar = calendar
        self.reflectionText = resolvedCoach.lastReflection
        self.suggestionText = resolvedCoach.lastSuggestion
    }

    // MARK: - Week window

    private var startOfToday: Date { calendar.startOfDay(for: .now) }

    /// Active week window — install-anchored for the user's first 7 days,
    /// rolling thereafter.
    var weekWindow: WeekWindow {
        WeekWindow.current(today: .now, calendar: calendar)
    }

    /// All 7 days the chart should render, in chronological order.
    var last7Days: [Date] { weekWindow.allDays }

    /// Per-day completion *ratio* (0…1) for the chart. Future days during
    /// week 1 are rendered as 0.
    var perDayRatios: [(date: Date, value: Double)] {
        let pastSet = Set(weekWindow.pastDays)
        return weekWindow.allDays.map { day in
            guard pastSet.contains(day) else { return (day, 0) }
            let scheduled = persistence.db.rhythms.filter { $0.isScheduled(on: day, calendar: calendar) }
            let total = scheduled.reduce(0) { $0 + $1.trackingBeats.count }
            guard total > 0 else { return (day, 0) }
            let completed = scheduled.reduce(0) { acc, rhythm in
                acc + rhythm.trackingBeats.filter {
                    persistence.isCompleted(beatID: $0.id, on: day, calendar: calendar)
                }.count
            }
            return (day, Double(completed) / Double(total))
        }
    }

    var totalCompletionsThisWeek: Int {
        // Only count completions inside elapsed days of the window — future
        // days don't have completions and shouldn't deflate the running total.
        weekWindow.pastDays.reduce(0) { acc, day in
            acc + persistence.db.completions.filter { c in
                calendar.isDate(c.completedAt, inSameDayAs: day)
            }.count
        }
    }

    var totalScheduledThisWeek: Int {
        var total = 0
        for day in weekWindow.pastDays {
            for rhythm in persistence.db.rhythms where rhythm.isScheduled(on: day, calendar: calendar) {
                total += rhythm.trackingBeats.count
            }
        }
        return total
    }

    var weeklyPercentage: Double {
        guard totalScheduledThisWeek > 0 else { return 0 }
        return Double(totalCompletionsThisWeek) / Double(totalScheduledThisWeek)
    }

    var momentumLevel: MomentumLevel { MomentumLevel.from(percentage: weeklyPercentage) }

    var bestBeatStreak: Int {
        var best = 0
        for rhythm in persistence.db.rhythms {
            for beat in rhythm.beats {
                let snap = StreakCalculator.beatStreak(
                    for: beat, in: rhythm,
                    completions: persistence.db.completions,
                    calendar: calendar
                )
                if snap.current > best { best = snap.current }
            }
        }
        return best
    }

    var bestRhythmStreak: Int {
        persistence.db.rhythms.map { rhythm in
            StreakCalculator.rhythmStreak(
                for: rhythm,
                completions: persistence.db.completions,
                calendar: calendar
            ).current
        }.max() ?? 0
    }

    var perRhythmBreakdown: [(rhythm: Rhythm, completionRate: Double, streak: Int)] {
        persistence.db.rhythms.map { rhythm in
            let scheduledDays = weekWindow.pastDays.filter { rhythm.isScheduled(on: $0, calendar: calendar) }
            let trackingPerDay = max(rhythm.trackingBeats.count, 1)
            let scheduledTotal = scheduledDays.count * trackingPerDay
            let completedTotal = scheduledDays.reduce(0) { acc, day in
                acc + rhythm.trackingBeats.filter {
                    persistence.isCompleted(beatID: $0.id, on: day, calendar: calendar)
                }.count
            }
            let rate: Double = scheduledTotal == 0 ? 0 : Double(completedTotal) / Double(scheduledTotal)
            let streak = StreakCalculator.rhythmStreak(
                for: rhythm,
                completions: persistence.db.completions,
                calendar: calendar
            ).current
            return (rhythm, rate, streak)
        }
    }

    var strongestRhythm: (rhythm: Rhythm, rate: Double)? {
        perRhythmBreakdown
            .filter { $0.completionRate > 0 }
            .max(by: { $0.completionRate < $1.completionRate })
            .map { ($0.rhythm, $0.completionRate) }
    }

    // MARK: - Recent reflections (for both Insights and AI prompts)

    /// Most-recent user reflections, newest first.
    var recentReflections: [(reflection: DailyReflection, rhythm: Rhythm)] {
        persistence.recentReflections(limit: 5).compactMap { r in
            guard let rhythm = persistence.db.rhythms.first(where: { $0.id == r.rhythmID })
            else { return nil }
            return (r, rhythm)
        }
    }

    private func reflectionsForPrompt() -> [WeeklySummary.Reflection] {
        // Take the newest reflections that fall inside the active week window.
        let cutoff = weekWindow.pastDays.first ?? startOfToday
        return persistence.recentReflections(limit: 3).compactMap { r in
            guard r.day >= cutoff,
                  let rhythm = persistence.db.rhythms.first(where: { $0.id == r.rhythmID })
            else { return nil }
            let comps = calendar.dateComponents([.day], from: r.day, to: startOfToday)
            return WeeklySummary.Reflection(
                rhythmName: rhythm.name,
                dayOffset: -(comps.day ?? 0),
                text: r.text
            )
        }
    }

    func summary() -> WeeklySummary {
        let breakdown = perRhythmBreakdown
        let best = breakdown.max(by: { $0.completionRate < $1.completionRate })
        let worst = breakdown.min(by: { $0.completionRate < $1.completionRate })
        let structure: [WeeklySummary.RhythmStructure] = persistence.db.rhythms.map { r in
            let beatTitles = r.sortedBeats.map { beat -> String in
                let suffix = beat.isRequired ? "" : " (opt)"
                return beat.name + suffix
            }
            let reminder: String?
            if let t = r.reminderTime {
                let f = DateFormatter()
                f.dateFormat = "HH:mm"
                reminder = f.string(from: t)
            } else {
                reminder = nil
            }
            return WeeklySummary.RhythmStructure(
                name: r.name,
                period: r.period.displayName,
                beatTitles: beatTitles,
                reminder: reminder
            )
        }
        return WeeklySummary(
            totalScheduled: totalScheduledThisWeek,
            totalCompleted: totalCompletionsThisWeek,
            bestRhythmName: best?.rhythm.name,
            strugglingRhythmName: worst?.rhythm.name,
            longestActiveStreak: max(bestBeatStreak, bestRhythmStreak),
            perRhythm: breakdown.map {
                WeeklySummary.PerRhythm(
                    name: $0.rhythm.name,
                    completionRate: $0.completionRate,
                    streak: $0.streak
                )
            },
            recentReflections: reflectionsForPrompt(),
            rhythmStructure: structure
        )
    }

    // MARK: - AI generation

    var canGenerate: Bool {
        guard !isGenerating else { return false }
        guard let last = lastGenerationAt else { return true }
        return Date().timeIntervalSince(last) >= rateLimitSeconds
    }

    var refreshCooldownRemaining: Int {
        guard let last = lastGenerationAt else { return 0 }
        let remaining = rateLimitSeconds - Date().timeIntervalSince(last)
        return max(0, Int(remaining.rounded(.up)))
    }

    var aiAvailability: AICoachService.AvailabilityStatus { aiCoach.availability }

    /// Stream the reflection and suggestion in parallel, updating the
    /// observable text properties progressively so the UI shows tokens as
    /// they're produced.
    func generate() async {
        guard !isGenerating else { return }
        let summary = summary()
        isGenerating = true
        defer { isGenerating = false }
        lastError = nil

        guard aiCoach.isAvailable else {
            reflectionText = aiCoach.ruleBasedReflection(summary: summary)
            suggestionText = aiCoach.ruleBasedSuggestion(summary: summary)
            lastGenerationAt = Date()
            return
        }

        // Reset placeholders so the user immediately sees the box clear.
        reflectionText = ""
        suggestionText = ""

        do {
            async let r: String = aiCoach.streamWeeklyReflection(summary: summary) { [weak self] partial in
                self?.reflectionText = partial
            }
            async let s: String = aiCoach.streamSuggestion(summary: summary) { [weak self] partial in
                self?.suggestionText = partial
            }
            // Wait for both to finish so we know to stamp the cooldown.
            _ = try await (r, s)
            lastGenerationAt = Date()
        } catch {
            lastError = error.localizedDescription
            // Graceful fallback so the cards never end up empty.
            if (reflectionText ?? "").isEmpty {
                reflectionText = aiCoach.ruleBasedReflection(summary: summary)
            }
            if (suggestionText ?? "").isEmpty {
                suggestionText = aiCoach.ruleBasedSuggestion(summary: summary)
            }
        }
    }

    func generateIfNeeded() async {
        // If Apple Intelligence is currently off, always show rule-based copy
        // — never the cached AI text from before the user disabled it.
        // Otherwise the footer ("Apple Intelligence is off") would contradict
        // the body of the card.
        if !aiCoach.isAvailable {
            let summary = summary()
            reflectionText = aiCoach.ruleBasedReflection(summary: summary)
            suggestionText = aiCoach.ruleBasedSuggestion(summary: summary)
            return
        }
        if reflectionText == nil || reflectionText?.isEmpty == true ||
            suggestionText == nil || suggestionText?.isEmpty == true {
            await generate()
        }
    }
}
