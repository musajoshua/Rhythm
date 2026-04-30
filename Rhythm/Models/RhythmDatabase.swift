//
//  RhythmDatabase.swift
//  Rhythm
//

import Foundation

/// The single persisted document. The whole database is one JSON file.
nonisolated struct RhythmDatabase: Codable, Sendable {
    var rhythms: [Rhythm]
    var completions: [Completion]
    var reflections: [DailyReflection]

    init(rhythms: [Rhythm] = [], completions: [Completion] = [],
         reflections: [DailyReflection] = []) {
        self.rhythms = rhythms
        self.completions = completions
        self.reflections = reflections
    }

    // Tolerant decoding so older payloads without `reflections` still load.
    private enum CodingKeys: String, CodingKey {
        case rhythms, completions, reflections
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.rhythms = try c.decode([Rhythm].self, forKey: .rhythms)
        self.completions = try c.decode([Completion].self, forKey: .completions)
        self.reflections = try c.decodeIfPresent([DailyReflection].self, forKey: .reflections) ?? []
    }

    static let empty = RhythmDatabase(rhythms: [], completions: [], reflections: [])
}
