//
//  RhythmsViewModel.swift
//  Rhythm
//

import Foundation
import Observation

@Observable
@MainActor
final class RhythmsViewModel {
    private let persistence: PersistenceService
    private let calendar: Calendar

    init(persistence: PersistenceService? = nil,
         calendar: Calendar = .current) {
        self.persistence = persistence ?? PersistenceService.shared
        self.calendar = calendar
    }

    var rhythms: [Rhythm] {
        persistence.db.rhythms.sorted { $0.createdAt < $1.createdAt }
    }

    func longestRhythmStreak(for rhythm: Rhythm) -> Int {
        StreakCalculator.rhythmStreak(
            for: rhythm,
            completions: persistence.db.completions,
            calendar: calendar
        ).best
    }

    func currentRhythmStreak(for rhythm: Rhythm) -> Int {
        StreakCalculator.rhythmStreak(
            for: rhythm,
            completions: persistence.db.completions,
            calendar: calendar
        ).current
    }

    func delete(rhythmID: UUID) {
        persistence.delete(rhythmID: rhythmID)
        Task { @MainActor in
            await NotificationService.shared.cancel(rhythmID: rhythmID)
        }
    }
}
