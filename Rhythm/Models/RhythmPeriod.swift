//
//  RhythmPeriod.swift
//  Rhythm
//
//  A loose time-of-day grouping for a routine. Adopted from the Rhythm2
//  design language so the home screen reads like an editorial dashboard
//  rather than a flat checklist.
//

import Foundation

nonisolated enum RhythmPeriod: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case morning
    case midday
    case evening
    case night
    case anytime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .midday:  return "Midday"
        case .evening: return "Evening"
        case .night:   return "Night"
        case .anytime: return "Anytime"
        }
    }

    /// Drives the natural reading order on the home screen.
    var sortIndex: Int {
        switch self {
        case .morning: return 0
        case .midday:  return 1
        case .evening: return 2
        case .night:   return 3
        case .anytime: return 4
        }
    }

    /// Default SF Symbol when the user hasn't picked one yet.
    var defaultIconName: String {
        switch self {
        case .morning: return "sunrise"
        case .midday:  return "sun.max"
        case .evening: return "sun.haze"
        case .night:   return "moon.stars"
        case .anytime: return "sparkles"
        }
    }

    /// Short, gentle subtitle suitable for cards.
    var tagline: String {
        switch self {
        case .morning: return "Start the day grounded"
        case .midday:  return "Reset and refocus"
        case .evening: return "Wind down with intent"
        case .night:   return "Rest, ready for tomorrow"
        case .anytime: return "Whenever it fits"
        }
    }

    /// Heuristic mapping from a 24h hour to a period — used as a sensible
    /// default whenever a rhythm doesn't carry an explicit period yet.
    static func from(hour: Int) -> RhythmPeriod {
        switch hour {
        case 0..<5:   return .night
        case 5..<11:  return .morning
        case 11..<15: return .midday
        case 15..<21: return .evening
        default:      return .night
        }
    }
}
