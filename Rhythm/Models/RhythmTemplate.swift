//
//  RhythmTemplate.swift
//  Rhythm
//
//  Curated starter rhythms shown during onboarding. The user can apply any
//  subset; each template materialises into a `Rhythm` with prefilled beats so
//  people start with momentum, not a blank canvas.
//

import Foundation

nonisolated struct RhythmTemplate: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let period: RhythmPeriod
    let iconName: String
    let summary: String
    let beats: [BeatTemplate]

    nonisolated struct BeatTemplate: Hashable, Sendable {
        let title: String
        let symbolName: String
        let durationMinutes: Int?
    }

    static let all: [RhythmTemplate] = [
        RhythmTemplate(
            id: "morning-reset",
            title: "Morning Reset",
            period: .morning,
            iconName: "sunrise",
            summary: "Wake up gently and set the tone for the day.",
            beats: [
                .init(title: "Drink a full glass of water", symbolName: "drop", durationMinutes: nil),
                .init(title: "Stretch for 5 minutes", symbolName: "figure.flexibility", durationMinutes: 5),
                .init(title: "Write today's intention", symbolName: "book.closed", durationMinutes: 5)
            ]
        ),
        RhythmTemplate(
            id: "study-focus",
            title: "Study Focus",
            period: .midday,
            iconName: "book.closed",
            summary: "A short midday block for deep work.",
            beats: [
                .init(title: "Review notes from yesterday", symbolName: "doc.text", durationMinutes: 5),
                .init(title: "One 25-minute focus session", symbolName: "timer", durationMinutes: 25),
                .init(title: "Tidy your workspace", symbolName: "tray", durationMinutes: 5)
            ]
        ),
        RhythmTemplate(
            id: "evening-winddown",
            title: "Evening Wind-down",
            period: .evening,
            iconName: "sun.haze",
            summary: "Slow your pace before sleep.",
            beats: [
                .init(title: "Step away from screens", symbolName: "iphone.slash", durationMinutes: nil),
                .init(title: "Plan tomorrow in one line", symbolName: "calendar", durationMinutes: 5),
                .init(title: "Read for 10 minutes", symbolName: "book", durationMinutes: 10)
            ]
        ),
        RhythmTemplate(
            id: "movement",
            title: "Daily Movement",
            period: .anytime,
            iconName: "figure.run",
            summary: "A gentle nudge to move your body each day.",
            beats: [
                .init(title: "Walk for 15 minutes", symbolName: "figure.walk", durationMinutes: 15),
                .init(title: "Stretch your back", symbolName: "figure.cooldown", durationMinutes: 5)
            ]
        )
    ]
}

extension RhythmTemplate {
    /// Materialise the template into a fresh `Rhythm` with a sensible default
    /// reminder time derived from the period.
    func makeRhythm() -> Rhythm {
        let materialised = beats.enumerated().map { idx, b in
            Beat(
                name: b.title,
                symbolName: b.symbolName,
                durationMinutes: b.durationMinutes,
                order: idx,
                isRequired: true
            )
        }
        return Rhythm(
            name: title,
            notes: summary,
            period: period,
            iconName: iconName,
            reminderTime: Self.defaultReminder(for: period),
            beats: materialised
        )
    }

    private static func defaultReminder(for period: RhythmPeriod) -> Date? {
        var comps = DateComponents()
        switch period {
        case .morning: comps.hour = 7;  comps.minute = 0
        case .midday:  comps.hour = 12; comps.minute = 0
        case .evening: comps.hour = 18; comps.minute = 0
        case .night:   comps.hour = 21; comps.minute = 30
        case .anytime: return nil
        }
        return Calendar.current.date(from: comps)
    }
}
