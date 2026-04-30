//
//  Rhythm.swift
//  Rhythm
//

import Foundation

/// A named routine. Holds an ordered list of beats. The schedule is light:
/// every active day, with an optional single daily reminder time.
nonisolated struct Rhythm: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    /// Optional notes shown under the title on the detail screen.
    var notes: String?
    /// Time-of-day grouping that drives ordering and palette tinting on the home screen.
    var period: RhythmPeriod
    /// SF Symbol shown in the rhythm's hero circle.
    var iconName: String
    /// Optional daily reminder. Only the hour and minute components matter;
    /// the date portion is ignored.
    var reminderTime: Date?
    /// Days of the week the rhythm is scheduled. Defaults to all 7.
    var activeDays: Set<Weekday>
    var beats: [Beat]
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        period: RhythmPeriod? = nil,
        iconName: String? = nil,
        reminderTime: Date? = nil,
        activeDays: Set<Weekday> = Set(Weekday.allCases),
        beats: [Beat] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        let resolvedPeriod = period ?? .anytime
        self.period = resolvedPeriod
        self.iconName = iconName ?? resolvedPeriod.defaultIconName
        self.reminderTime = reminderTime
        self.activeDays = activeDays
        self.beats = beats
        self.createdAt = createdAt
    }

    // MARK: - Codable (tolerant of older payloads)

    private enum CodingKeys: String, CodingKey {
        case id, name, notes, period, iconName, reminderTime, activeDays, beats, createdAt
        // Legacy keys kept for backward compatibility
        case startHour, startMinute, endHour, endMinute, accentHex, notificationsEnabled
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encode(period, forKey: .period)
        try c.encode(iconName, forKey: .iconName)
        try c.encodeIfPresent(reminderTime, forKey: .reminderTime)
        try c.encode(activeDays, forKey: .activeDays)
        try c.encode(beats, forKey: .beats)
        try c.encode(createdAt, forKey: .createdAt)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = try c.decode(UUID.self, forKey: .id)
        let name = try c.decode(String.self, forKey: .name)
        let activeDays = try c.decodeIfPresent(Set<Weekday>.self, forKey: .activeDays)
            ?? Set(Weekday.allCases)
        let beats = try c.decode([Beat].self, forKey: .beats)
        let createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        let notes = try c.decodeIfPresent(String.self, forKey: .notes)
        // Period: prefer explicit; fall back to derived from legacy startHour.
        let period: RhythmPeriod
        if let explicit = try c.decodeIfPresent(RhythmPeriod.self, forKey: .period) {
            period = explicit
        } else if let startHour = try c.decodeIfPresent(Int.self, forKey: .startHour) {
            period = RhythmPeriod.from(hour: startHour)
        } else {
            period = .anytime
        }
        let iconName = try c.decodeIfPresent(String.self, forKey: .iconName)
            ?? period.defaultIconName

        // Reminder time: prefer explicit; fall back to legacy startHour:startMinute
        // when the legacy `notificationsEnabled` flag was true.
        var reminder = try c.decodeIfPresent(Date.self, forKey: .reminderTime)
        if reminder == nil,
           let startHour = try c.decodeIfPresent(Int.self, forKey: .startHour),
           let startMinute = try c.decodeIfPresent(Int.self, forKey: .startMinute),
           (try? c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled)) == true {
            var comps = DateComponents()
            comps.hour = startHour
            comps.minute = startMinute
            reminder = Calendar.current.date(from: comps)
        }

        self.id = id
        self.name = name
        self.notes = notes
        self.period = period
        self.iconName = iconName
        self.reminderTime = reminder
        self.activeDays = activeDays
        self.beats = beats
        self.createdAt = createdAt
    }

    // MARK: - Convenience

    var sortedBeats: [Beat] {
        beats.sorted { $0.order < $1.order }
    }

    /// Beats that count toward "rhythm complete". Falls back to all beats when
    /// the user hasn't marked any as required, so an all-optional rhythm still
    /// produces meaningful progress.
    var trackingBeats: [Beat] {
        let required = sortedBeats.filter { $0.isRequired }
        return required.isEmpty ? sortedBeats : required
    }

    /// Reminder time formatted as "HH:mm", or nil if no reminder is set.
    var reminderText: String? {
        guard let reminderTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: reminderTime)
    }

    /// True if this rhythm is scheduled on the given date.
    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        activeDays.contains(Weekday.from(date: date, calendar: calendar))
    }
}
