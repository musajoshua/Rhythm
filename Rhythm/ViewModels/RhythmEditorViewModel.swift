//
//  RhythmEditorViewModel.swift
//  Rhythm
//
//  Streamlined Rhythm2-style editor: name, notes, period, icon, optional
//  daily reminder, and a list of beats with required/optional toggle and an
//  optional details note.
//

import Foundation
import Observation

@Observable
@MainActor
final class RhythmEditorViewModel {
    private let persistence: PersistenceService
    private let originalID: UUID?

    /// Lightweight value-typed working copy of a beat. Avoids round-tripping
    /// the persisted `Beat` while the user is mid-edit.
    struct BeatDraft: Identifiable, Hashable {
        let id: UUID
        var name: String
        var symbolName: String
        var details: String
        var isRequired: Bool
        var durationMinutes: Int?
    }

    // Editable state
    var name: String
    var notes: String
    var period: RhythmPeriod
    var iconName: String
    var hasReminder: Bool
    var reminderTime: Date
    var activeDays: Set<Weekday>
    var beats: [BeatDraft]

    /// Whether the user manually picked an icon — used to auto-update the icon
    /// when they switch periods (only when they haven't picked one).
    private var iconPickedManually: Bool

    init(existing: Rhythm? = nil, persistence: PersistenceService? = nil) {
        self.persistence = persistence ?? PersistenceService.shared
        self.originalID = existing?.id

        if let r = existing {
            self.name = r.name
            self.notes = r.notes ?? ""
            self.period = r.period
            self.iconName = r.iconName
            self.hasReminder = r.reminderTime != nil
            self.reminderTime = r.reminderTime ?? Self.defaultReminder(for: r.period)
            self.activeDays = r.activeDays
            self.beats = r.sortedBeats.map {
                BeatDraft(
                    id: $0.id,
                    name: $0.name,
                    symbolName: $0.symbolName,
                    details: $0.details ?? "",
                    isRequired: $0.isRequired,
                    durationMinutes: $0.durationMinutes
                )
            }
            self.iconPickedManually = r.iconName != r.period.defaultIconName
        } else {
            // Default the period to whatever bracket of the day the user is in
            // right now — saves a tap on the period picker for new rhythms.
            let nowHour = Calendar.current.component(.hour, from: Date())
            let smartPeriod = RhythmPeriod.from(hour: nowHour)
            self.name = ""
            self.notes = ""
            self.period = smartPeriod
            self.iconName = smartPeriod.defaultIconName
            self.hasReminder = false
            self.reminderTime = Self.defaultReminder(for: smartPeriod)
            self.activeDays = Set(Weekday.allCases)
            self.beats = [
                BeatDraft(id: UUID(), name: "", symbolName: "circle",
                          details: "", isRequired: true, durationMinutes: nil)
            ]
            self.iconPickedManually = false
        }
    }

    private static func defaultReminder(for period: RhythmPeriod) -> Date {
        var comps = DateComponents()
        switch period {
        case .morning: comps.hour = 7;  comps.minute = 0
        case .midday:  comps.hour = 12; comps.minute = 0
        case .evening: comps.hour = 18; comps.minute = 0
        case .night:   comps.hour = 21; comps.minute = 30
        case .anytime: comps.hour = 9;  comps.minute = 0
        }
        return Calendar.current.date(from: comps) ?? Date()
    }

    // MARK: - Validation

    var nameFieldError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Name is required." }
        if trimmed.count > 40 { return "Keep it under 40 characters." }
        return nil
    }

    var canSave: Bool {
        nameFieldError == nil
            && !beats.isEmpty
            && beats.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var isEditing: Bool { originalID != nil }

    /// Total beats that would exist across the whole DB after this save.
    /// Used by the paywall gate when the user is on the free tier.
    var projectedTotalBeats: Int {
        let othersBeats = persistence.db.rhythms
            .filter { $0.id != originalID }
            .reduce(0) { $0 + $1.beats.count }
        return othersBeats + beats.count
    }

    /// True when the projected total is allowed by the current tier.
    var savingFitsFreeTier: Bool {
        Pricing.canSaveWithBeatTotal(projectedTotalBeats)
    }

    // MARK: - Mutations

    func didChangePeriod() {
        if !iconPickedManually {
            iconName = period.defaultIconName
        }
        if !hasReminder {
            reminderTime = Self.defaultReminder(for: period)
        }
    }

    func pickIcon(_ name: String) {
        iconName = name
        iconPickedManually = true
    }

    func addBeat() {
        beats.append(BeatDraft(id: UUID(), name: "", symbolName: "circle",
                                details: "", isRequired: true, durationMinutes: nil))
    }

    func removeBeat(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where beats.indices.contains(index) {
            beats.remove(at: index)
        }
    }

    func moveBeat(from source: IndexSet, to destination: Int) {
        let sortedIndices = source.sorted()
        let movingItems = sortedIndices.map { beats[$0] }
        let removedBefore = sortedIndices.filter { $0 < destination }.count
        let adjustedDestination = destination - removedBefore
        for index in sortedIndices.reversed() {
            beats.remove(at: index)
        }
        let insertionIndex = max(0, min(adjustedDestination, beats.count))
        beats.insert(contentsOf: movingItems, at: insertionIndex)
    }

    // MARK: - Save / Delete

    @discardableResult
    func save() -> Rhythm? {
        guard canSave else { return nil }
        let materialised = beats.enumerated().map { idx, draft in
            Beat(
                id: draft.id,
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                symbolName: draft.symbolName,
                durationMinutes: draft.durationMinutes,
                order: idx,
                isRequired: draft.isRequired,
                details: draft.details.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            )
        }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let rhythm = Rhythm(
            id: originalID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: trimmedNotes,
            period: period,
            iconName: iconName,
            reminderTime: hasReminder ? reminderTime : nil,
            activeDays: activeDays,
            beats: materialised,
            createdAt: persistence.db.rhythms.first(where: { $0.id == originalID })?.createdAt ?? Date()
        )
        persistence.upsert(rhythm)
        Task { @MainActor in
            await NotificationService.shared.reschedule(for: rhythm)
        }
        return rhythm
    }

    func delete() {
        guard let id = originalID else { return }
        persistence.delete(rhythmID: id)
        Task { @MainActor in
            await NotificationService.shared.cancel(rhythmID: id)
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
