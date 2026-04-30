//
//  DailyReflection.swift
//  Rhythm
//
//  A short note the user writes about how a rhythm went on a given day.
//  Stored as one record per (rhythmID, day) pair. Surfaced on the rhythm
//  detail screen and aggregated on Insights.
//

import Foundation

nonisolated struct DailyReflection: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var rhythmID: UUID
    /// Calendar day the reflection is for (start-of-day in the user's calendar).
    var day: Date
    var text: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        rhythmID: UUID,
        day: Date,
        text: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.rhythmID = rhythmID
        self.day = day
        self.text = text
        self.updatedAt = updatedAt
    }
}
