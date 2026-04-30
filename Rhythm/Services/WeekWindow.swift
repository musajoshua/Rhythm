//
//  WeekWindow.swift
//  Rhythm
//
//  Decides which 7 days the home and insights screens should display.
//
//  Behaviour:
//   - During the user's first 7 days (install day + 6), the window is
//     anchored to the install date and grows forward — the chart shows
//     install day on the left and 6 future days on the right. Future days
//     have no data yet but are visible as empty placeholders.
//   - After day 7, the window switches to a standard rolling 7-day view
//     ending at today.
//
//  `pastDays` is the subset of the window that has actually elapsed and is
//  what averages and totals should be computed from — including future days
//  in the denominator would unfairly drag a new user's stats down to zero.
//

import Foundation

nonisolated struct WeekWindow: Sendable {
    /// All 7 days of the window in chronological order. Always 7 entries.
    let allDays: [Date]
    /// Subset of `allDays` that is on or before today.
    let pastDays: [Date]
    /// True while the window is still anchored to the install date.
    let isFirstWeek: Bool
    /// Human label describing the window (e.g. "Your first 7 days" / "Last 7 days").
    let label: String
}

extension WeekWindow {
    static func current(today: Date = .now,
                        installDate: Date = InstallationDate.date,
                        calendar: Calendar = .current) -> WeekWindow {
        let installDay = calendar.startOfDay(for: installDate)
        let todayDay = calendar.startOfDay(for: today)
        guard let firstWeekEnd = calendar.date(byAdding: .day, value: 6, to: installDay)
        else { return rolling(today: todayDay, calendar: calendar) }

        if todayDay <= firstWeekEnd {
            let allDays = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: installDay)
            }
            let pastDays = allDays.filter { $0 <= todayDay }
            return WeekWindow(
                allDays: allDays,
                pastDays: pastDays,
                isFirstWeek: true,
                label: "Your first 7 days"
            )
        }

        return rolling(today: todayDay, calendar: calendar)
    }

    private static func rolling(today: Date, calendar: Calendar) -> WeekWindow {
        let allDays: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.reversed()
        return WeekWindow(
            allDays: allDays,
            pastDays: allDays,
            isFirstWeek: false,
            label: "Last 7 days"
        )
    }
}
