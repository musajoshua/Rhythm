//
//  Weekday.swift
//  Rhythm
//

import Foundation

/// Mon–Sun weekday enum. ISO-like ordering: Monday = 1.
nonisolated enum Weekday: Int, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    /// Single-character label for compact day pills (M T W T F S S).
    var shortLabel: String {
        ["M", "T", "W", "T", "F", "S", "S"][rawValue - 1]
    }

    /// Full English name.
    var fullName: String {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][rawValue - 1]
    }

    /// Map an ISO-style Calendar weekday (1=Sunday … 7=Saturday) to our enum.
    static func from(date: Date, calendar: Calendar = .current) -> Weekday {
        // Calendar.weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        let cw = calendar.component(.weekday, from: date)
        switch cw {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}
