//
//  TodayViewModel.swift
//  Rhythm
//

import Foundation
import Observation

@Observable
@MainActor
final class TodayViewModel {
    private let persistence: PersistenceService
    private let calendar: Calendar

    /// Re-derive today on access (let the system pick up date changes).
    var today: Date { calendar.startOfDay(for: .now) }

    init(persistence: PersistenceService? = nil,
         calendar: Calendar = .current) {
        self.persistence = persistence ?? PersistenceService.shared
        self.calendar = calendar
    }

    // MARK: - Today's rhythms

    /// Rhythms scheduled today, sorted by period and reminder time.
    var rhythmsScheduledToday: [Rhythm] {
        persistence.db.rhythms
            .filter { $0.isScheduled(on: today, calendar: calendar) }
            .sorted { lhs, rhs in
                if lhs.period.sortIndex != rhs.period.sortIndex {
                    return lhs.period.sortIndex < rhs.period.sortIndex
                }
                let lTime = reminderMinutes(for: lhs)
                let rTime = reminderMinutes(for: rhs)
                return lTime < rTime
            }
    }

    var totalBeatsToday: Int {
        rhythmsScheduledToday.reduce(0) { $0 + $1.trackingBeats.count }
    }

    var completedTrackingBeatsToday: Int {
        rhythmsScheduledToday.reduce(0) { acc, rhythm in
            acc + rhythm.trackingBeats.filter {
                persistence.isCompleted(beatID: $0.id, on: today, calendar: calendar)
            }.count
        }
    }

    /// 0…1 — proportion of today's required beats already completed.
    var todayProgress: Double {
        guard totalBeatsToday > 0 else { return 0 }
        return Double(completedTrackingBeatsToday) / Double(totalBeatsToday)
    }

    var greeting: String {
        let hour = calendar.component(.hour, from: .now)
        switch hour {
        case 0..<5:   return "Late night"
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }

    var dateLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: .now)
    }

    // MARK: - Per-rhythm progress

    /// 0…1 fraction of `trackingBeats` completed today.
    func progress(for rhythm: Rhythm) -> Double {
        let total = rhythm.trackingBeats.count
        guard total > 0 else { return 0 }
        let done = rhythm.trackingBeats.filter {
            persistence.isCompleted(beatID: $0.id, on: today, calendar: calendar)
        }.count
        return Double(done) / Double(total)
    }

    /// Total beats (required + optional) completed today for this rhythm.
    func completedCount(for rhythm: Rhythm) -> Int {
        rhythm.beats.filter {
            persistence.isCompleted(beatID: $0.id, on: today, calendar: calendar)
        }.count
    }

    /// Current rhythm-level streak — for the small chip on the Today card.
    func rhythmStreak(for rhythm: Rhythm) -> Int {
        StreakCalculator.rhythmStreak(
            for: rhythm,
            completions: persistence.db.completions,
            today: .now,
            calendar: calendar
        ).current
    }

    // MARK: - Momentum (week window)

    private var weekWindow: WeekWindow {
        WeekWindow.current(today: .now, calendar: calendar)
    }

    var momentumSummary: MomentumSummary {
        let perDay = perDayProgress()
        // Average over actually-elapsed days only — future placeholders during
        // the first week shouldn't drag a brand-new user's average to zero.
        let elapsedCount = weekWindow.pastDays.count
        let elapsedSum = perDay.prefix(elapsedCount).reduce(0, +)
        let avg = elapsedCount == 0 ? 0 : elapsedSum / Double(elapsedCount)
        return MomentumSummary(
            percentage: avg,
            perDay: perDay,
            level: MomentumLevel.from(percentage: avg)
        )
    }

    private func perDayProgress() -> [Double] {
        let pastSet = Set(weekWindow.pastDays)
        return weekWindow.allDays.map { day in
            // Future days during week 1 render as empty pips.
            guard pastSet.contains(day) else { return 0 }
            let scheduled = persistence.db.rhythms.filter { $0.isScheduled(on: day, calendar: calendar) }
            let total = scheduled.reduce(0) { $0 + $1.trackingBeats.count }
            guard total > 0 else { return 0 }
            let completed = scheduled.reduce(0) { acc, rhythm in
                acc + rhythm.trackingBeats.filter {
                    persistence.isCompleted(beatID: $0.id, on: day, calendar: calendar)
                }.count
            }
            return Double(completed) / Double(total)
        }
    }

    // MARK: - Helpers

    private func reminderMinutes(for rhythm: Rhythm) -> Int {
        guard let r = rhythm.reminderTime else {
            // No reminder → sort by period default order at end of day.
            return 24 * 60
        }
        let comps = calendar.dateComponents([.hour, .minute], from: r)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
}
