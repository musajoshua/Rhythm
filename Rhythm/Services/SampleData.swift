//
//  SampleData.swift
//  Rhythm
//

import Foundation

enum SampleData {
    static func makeSampleDatabase() -> RhythmDatabase {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // -- Morning Reset --
        let stretchBeat = Beat(name: "Stretch", symbolName: "figure.flexibility",
                               durationMinutes: 10, order: 0, isRequired: true)
        let meditateBeat = Beat(name: "Meditate", symbolName: "brain.head.profile",
                                durationMinutes: 10, order: 1, isRequired: true,
                                details: "Two minutes of breath-following is enough.")
        let journalBeat = Beat(name: "Journal", symbolName: "book.closed",
                               durationMinutes: 5, order: 2, isRequired: false,
                               details: "One sentence about how today should feel.")
        let morning = Rhythm(
            name: "Morning Reset",
            notes: "A gentle on-ramp into the day.",
            period: .morning,
            iconName: "sunrise",
            reminderTime: dateAt(hour: 7, minute: 0),
            beats: [stretchBeat, meditateBeat, journalBeat]
        )

        // -- Wind-Down --
        let readBeat = Beat(name: "Read 10 pages", symbolName: "book",
                            durationMinutes: 15, order: 0, isRequired: true)
        let teaBeat = Beat(name: "Herbal tea", symbolName: "cup.and.saucer",
                           durationMinutes: nil, order: 1, isRequired: false)
        let plannerBeat = Beat(name: "Plan tomorrow", symbolName: "calendar",
                               durationMinutes: 5, order: 2, isRequired: true,
                               details: "Three bullets max.")
        let windDown = Rhythm(
            name: "Wind-Down",
            notes: "Slow your pace before sleep.",
            period: .night,
            iconName: "moon.stars",
            reminderTime: dateAt(hour: 21, minute: 30),
            beats: [readBeat, teaBeat, plannerBeat]
        )

        // -- Deep-Work --
        let focusBeat = Beat(name: "60 min focus block", symbolName: "timer",
                             durationMinutes: 60, order: 0, isRequired: true)
        let walkBeat = Beat(name: "Walk break", symbolName: "figure.walk",
                            durationMinutes: 10, order: 1, isRequired: false,
                            details: "Step away from the screen.")
        let deepWork = Rhythm(
            name: "Deep-Work",
            notes: "A short midday block for deep work.",
            period: .midday,
            iconName: "sun.max",
            reminderTime: dateAt(hour: 10, minute: 0),
            activeDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            beats: [focusBeat, walkBeat]
        )

        var completions: [Completion] = []

        // Morning: 6 of last 7 days, all beats. Day -3 only stretch+meditate.
        for offset in (-6...0) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let isStruggleDay = (offset == -3)
            for beat in morning.beats {
                if isStruggleDay && beat.id == journalBeat.id { continue }
                completions.append(Completion(beatID: beat.id, rhythmID: morning.id, completedAt: day))
            }
        }

        // Wind-Down: only 2 of last 7 days (struggling).
        for offset in [-1, -5] {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            for beat in windDown.beats {
                completions.append(Completion(beatID: beat.id, rhythmID: windDown.id, completedAt: day))
            }
        }

        // Deep-Work: most weekdays.
        for offset in (-6...0) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let weekday = Weekday.from(date: day, calendar: calendar)
            guard deepWork.activeDays.contains(weekday) else { continue }
            for beat in deepWork.beats {
                completions.append(Completion(beatID: beat.id, rhythmID: deepWork.id, completedAt: day))
            }
        }

        // -- Reflections (just a few, recent) --
        var reflections: [DailyReflection] = []
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) {
            reflections.append(DailyReflection(
                rhythmID: morning.id,
                day: twoDaysAgo,
                text: "Mornings have felt easier lately — sitting on the mat first is the trick.",
                updatedAt: twoDaysAgo.addingTimeInterval(60 * 60 * 9)
            ))
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            reflections.append(DailyReflection(
                rhythmID: windDown.id,
                day: yesterday,
                text: "Stayed on the phone too long, ended up reading at 11. Tomorrow: tea first.",
                updatedAt: yesterday.addingTimeInterval(60 * 60 * 22)
            ))
        }
        if let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today) {
            reflections.append(DailyReflection(
                rhythmID: deepWork.id,
                day: threeDaysAgo,
                text: "One block was enough today; the second one would have been forced.",
                updatedAt: threeDaysAgo.addingTimeInterval(60 * 60 * 13)
            ))
        }

        return RhythmDatabase(
            rhythms: [morning, windDown, deepWork],
            completions: completions,
            reflections: reflections
        )
    }

    private static func dateAt(hour: Int, minute: Int) -> Date {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }
}
