//
//  PersistenceService.swift
//  Rhythm
//
//  Persists the full RhythmDatabase as a single JSON document inside the app's
//  Documents directory. Saves are debounced (0.3s) so rapid mutations coalesce
//  into a single atomic file write.
//

import Foundation
import Observation
import OSLog
import UniformTypeIdentifiers

@Observable
@MainActor
final class PersistenceService {
    static let shared = PersistenceService()

    /// In-memory database. Views/ViewModels read this; mutations go through helpers.
    private(set) var db: RhythmDatabase = .empty

    /// Debounced save handle. Cancelled and replaced on every `scheduleSave()`.
    private var saveTask: Task<Void, Never>?

    private let fileName = "rhythm_db.json"
    private let log = Logger(subsystem: "com.musajoshua.Rhythm", category: "Persistence")

    init() {}

    // MARK: - File location

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return docs.appendingPathComponent(fileName, conformingTo: .json)
    }

    // MARK: - Load / Save

    /// Synchronously load the database at app launch. Failures are non-fatal —
    /// we fall back to `.empty` so the app always starts.
    func load() {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            log.info("No persisted db found — starting fresh.")
            db = .empty
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            db = try decoder.decode(RhythmDatabase.self, from: data)
            log.info("Loaded \(self.db.rhythms.count) rhythms, \(self.db.completions.count) completions.")
        } catch {
            log.error("Failed to decode db, starting fresh: \(error.localizedDescription)")
            db = .empty
        }
    }

    /// Schedule a debounced save. Call after any mutation.
    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self else { return }
            await self.persist()
        }
    }

    private func persist() async {
        let snapshot = db
        let url = fileURL
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: url, options: [.atomic])
            log.debug("Persisted db (\(data.count) bytes).")
        } catch {
            log.error("Persist failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Rhythm CRUD

    func upsert(_ rhythm: Rhythm) {
        if let idx = db.rhythms.firstIndex(where: { $0.id == rhythm.id }) {
            db.rhythms[idx] = rhythm
        } else {
            db.rhythms.append(rhythm)
        }
        scheduleSave()
    }

    func delete(rhythmID: UUID) {
        db.rhythms.removeAll { $0.id == rhythmID }
        db.completions.removeAll { $0.rhythmID == rhythmID }
        db.reflections.removeAll { $0.rhythmID == rhythmID }
        scheduleSave()
    }

    // MARK: - Completion CRUD

    func add(completion: Completion) {
        db.completions.append(completion)
        scheduleSave()
    }

    /// Remove all completions for a beat on the given calendar day.
    func removeCompletion(beatID: UUID, on date: Date, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: date)
        db.completions.removeAll { c in
            c.beatID == beatID && calendar.isDate(c.completedAt, inSameDayAs: day)
        }
        scheduleSave()
    }

    /// Toggle a beat for the given date. If a completion exists today, remove it;
    /// otherwise insert a new one.
    @discardableResult
    func toggleCompletion(beatID: UUID, rhythmID: UUID, on date: Date = .now,
                          calendar: Calendar = .current) -> Bool {
        if isCompleted(beatID: beatID, on: date, calendar: calendar) {
            removeCompletion(beatID: beatID, on: date, calendar: calendar)
            return false
        } else {
            add(completion: Completion(beatID: beatID, rhythmID: rhythmID, completedAt: date))
            return true
        }
    }

    func isCompleted(beatID: UUID, on date: Date, calendar: Calendar = .current) -> Bool {
        db.completions.contains { c in
            c.beatID == beatID && calendar.isDate(c.completedAt, inSameDayAs: date)
        }
    }

    // MARK: - Reflection CRUD

    /// Find the reflection for a rhythm on a given day, if any.
    func reflection(for rhythmID: UUID, on date: Date,
                    calendar: Calendar = .current) -> DailyReflection? {
        let day = calendar.startOfDay(for: date)
        return db.reflections.first { r in
            r.rhythmID == rhythmID && calendar.isDate(r.day, inSameDayAs: day)
        }
    }

    /// Upsert the reflection for a (rhythmID, day) pair. Empty text removes
    /// any existing reflection so we don't keep blank notes around.
    func saveReflection(rhythmID: UUID, on date: Date, text: String,
                        calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: date)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Drop empty reflections.
        if trimmed.isEmpty {
            db.reflections.removeAll { r in
                r.rhythmID == rhythmID && calendar.isDate(r.day, inSameDayAs: day)
            }
            scheduleSave()
            return
        }

        if let idx = db.reflections.firstIndex(where: { r in
            r.rhythmID == rhythmID && calendar.isDate(r.day, inSameDayAs: day)
        }) {
            db.reflections[idx].text = trimmed
            db.reflections[idx].updatedAt = Date()
        } else {
            db.reflections.append(
                DailyReflection(rhythmID: rhythmID, day: day, text: trimmed)
            )
        }
        scheduleSave()
    }

    /// Most recent reflections, newest first, optionally limited.
    func recentReflections(limit: Int = 5) -> [DailyReflection] {
        Array(db.reflections.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(limit))
    }

    /// Most recent reflections for a specific rhythm, newest first.
    func recentReflections(for rhythmID: UUID, limit: Int = 10) -> [DailyReflection] {
        Array(
            db.reflections
                .filter { $0.rhythmID == rhythmID }
                .sorted(by: { $0.day > $1.day })
                .prefix(limit)
        )
    }

    // MARK: - Reset

    func resetAll() {
        db = .empty
        scheduleSave()
    }

    /// Replace the entire DB. Used by debug seed.
    func replace(with newDB: RhythmDatabase) {
        db = newDB
        scheduleSave()
    }

    // MARK: - Preview / Debug helpers

    /// In-memory preview instance pre-seeded with sample data.
    static var preview: PersistenceService {
        let svc = PersistenceService()
        svc.db = SampleData.makeSampleDatabase()
        return svc
    }
}
