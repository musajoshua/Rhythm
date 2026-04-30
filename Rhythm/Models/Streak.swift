//
//  Streak.swift
//  Rhythm
//

import Foundation

/// Computed streak snapshot. Not persisted — recomputed from `Completion` history.
nonisolated struct StreakSnapshot: Hashable, Sendable {
    let current: Int
    let best: Int
    let usedGraceDayThisWeek: Bool

    static let zero = StreakSnapshot(current: 0, best: 0, usedGraceDayThisWeek: false)
}
