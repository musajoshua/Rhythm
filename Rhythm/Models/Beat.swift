//
//  Beat.swift
//  Rhythm
//

import Foundation

/// A single habit inside a rhythm. The "beat" of the routine.
nonisolated struct Beat: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    /// SF Symbol name. e.g. "figure.mind.and.body".
    var symbolName: String
    var durationMinutes: Int?
    /// Display order within the parent rhythm.
    var order: Int
    /// Required beats count toward rhythm completion. Optional beats are
    /// nice-to-haves and don't break a streak when skipped.
    var isRequired: Bool
    /// A short additional description shown below the beat name on detail.
    var details: String?

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "circle",
        durationMinutes: Int? = nil,
        order: Int = 0,
        isRequired: Bool = true,
        details: String? = nil
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.durationMinutes = durationMinutes
        self.order = order
        self.isRequired = isRequired
        self.details = details
    }

    // MARK: - Codable (tolerant of older payloads)

    private enum CodingKeys: String, CodingKey {
        case id, name, symbolName, durationMinutes, order, isRequired, details
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.symbolName = try c.decode(String.self, forKey: .symbolName)
        self.durationMinutes = try c.decodeIfPresent(Int.self, forKey: .durationMinutes)
        self.order = try c.decode(Int.self, forKey: .order)
        self.isRequired = try c.decodeIfPresent(Bool.self, forKey: .isRequired) ?? true
        self.details = try c.decodeIfPresent(String.self, forKey: .details)
    }
}
