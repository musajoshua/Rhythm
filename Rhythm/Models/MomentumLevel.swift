//
//  MomentumLevel.swift
//  Rhythm
//
//  A coarse, human-readable summary of recent consistency. Computed from
//  the rolling 7-day completion percentage, used wherever we want to talk
//  about "how the week has felt" without surfacing raw streak numbers.
//

import Foundation

nonisolated enum MomentumLevel: String, Codable, CaseIterable, Hashable, Sendable {
    case low
    case building
    case strong
    case lockedIn

    var displayName: String {
        switch self {
        case .low:       return "Low"
        case .building:  return "Building"
        case .strong:    return "Strong"
        case .lockedIn:  return "Locked In"
        }
    }

    /// Calm, descriptive copy for the momentum card.
    var description: String {
        switch self {
        case .low:
            return "Your rhythm is quiet right now. One small beat today is enough."
        case .building:
            return "You're finding your pace. Consistency compounds quickly from here."
        case .strong:
            return "Your week has shape. Keep the cadence light and steady."
        case .lockedIn:
            return "Locked in. You're moving with your day, not against it."
        }
    }

    /// Maps a 0…1 completion ratio to a momentum level.
    static func from(percentage: Double) -> MomentumLevel {
        let pct = max(0, min(1, percentage))
        switch pct {
        case ..<0.25: return .low
        case ..<0.50: return .building
        case ..<0.80: return .strong
        default:      return .lockedIn
        }
    }
}
