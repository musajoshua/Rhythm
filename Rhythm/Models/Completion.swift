//
//  Completion.swift
//  Rhythm
//

import Foundation

/// A timestamped record that a beat was completed.
nonisolated struct Completion: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var beatID: UUID
    var rhythmID: UUID
    var completedAt: Date

    init(
        id: UUID = UUID(),
        beatID: UUID,
        rhythmID: UUID,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.beatID = beatID
        self.rhythmID = rhythmID
        self.completedAt = completedAt
    }
}
