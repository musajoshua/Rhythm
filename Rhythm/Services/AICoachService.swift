//
//  AICoachService.swift
//  Rhythm
//
//  Wrapper around Apple's on-device Foundation Models framework.
//  All processing happens on-device. No network. No API keys.
//
//  Features:
//   - Availability check that maps the framework's enum to our own UI cases.
//   - Streaming generation so the user sees text appear progressively.
//   - Rule-based fallbacks when Apple Intelligence is unavailable so the UI
//     is never empty.
//   - Per-ISO-week caching of the latest reflection + suggestion.
//

import Foundation
import Observation
import OSLog

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Weekly summary

/// Strongly-typed weekly snapshot passed to the LLM as structured prose.
nonisolated struct WeeklySummary: Sendable {
    let totalScheduled: Int
    let totalCompleted: Int
    let bestRhythmName: String?
    let strugglingRhythmName: String?
    let longestActiveStreak: Int
    let perRhythm: [PerRhythm]
    /// Up to 3 most-recent user reflections — short notes the user wrote at
    /// the bottom of the rhythm detail screen. Used as additional context so
    /// the coach can echo the user's own language back to them.
    let recentReflections: [Reflection]
    /// Rhythm-level structure: lets the model suggest concrete adjustments
    /// (add a hydration beat, move the reminder, etc.) grounded in what the
    /// user actually has set up — not just numbers.
    let rhythmStructure: [RhythmStructure]

    nonisolated struct PerRhythm: Sendable {
        let name: String
        let completionRate: Double // 0–1
        let streak: Int
    }

    nonisolated struct Reflection: Sendable {
        let rhythmName: String
        let dayOffset: Int  // 0 = today, -1 = yesterday, …
        let text: String
    }

    /// One row per rhythm describing its shape, so the coach can suggest a
    /// structural tweak rather than only a behavioural one.
    nonisolated struct RhythmStructure: Sendable {
        let name: String
        let period: String          // "Morning" / "Midday" / …
        let beatTitles: [String]    // ordered, "(opt)" suffix on optional beats
        let reminder: String?       // "07:00" or nil
    }

    var completionPercent: Int {
        guard totalScheduled > 0 else { return 0 }
        return Int((Double(totalCompleted) / Double(totalScheduled) * 100).rounded())
    }
}

// MARK: - Service

@Observable
@MainActor
final class AICoachService {
    static let shared = AICoachService()

    enum AvailabilityStatus: Equatable {
        case available
        case unavailableDeviceUnsupported
        case unavailableAppleIntelligenceOff
        case unavailableModelNotReady
    }

    enum AICoachError: LocalizedError {
        case unavailable
        case generationFailed(String)

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Apple Intelligence is unavailable on this device."
            case .generationFailed(let msg):
                return msg
            }
        }
    }

    private let log = Logger(subsystem: "com.musajoshua.Rhythm", category: "AICoach")

    /// Cached results. Rendered immediately on launch and refreshed when the
    /// user asks for a regeneration.
    private(set) var lastReflection: String?
    private(set) var lastSuggestion: String?
    private(set) var lastGeneratedAt: Date?

    private let reflectionKey = "rhythm.lastReflection"
    private let suggestionKey = "rhythm.lastSuggestion"
    private let weekKey = "rhythm.lastReflectionWeek"

    init() { loadCached() }

    // MARK: - Availability

    var availability: AvailabilityStatus {
#if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .unavailableDeviceUnsupported
            case .appleIntelligenceNotEnabled:
                return .unavailableAppleIntelligenceOff
            case .modelNotReady:
                return .unavailableModelNotReady
            @unknown default:
                return .unavailableModelNotReady
            }
        @unknown default:
            return .unavailableModelNotReady
        }
#else
        return .unavailableDeviceUnsupported
#endif
    }

    var isAvailable: Bool { availability == .available }

    // MARK: - Streaming generation

    /// Stream a weekly reflection. The closure is invoked progressively with
    /// the cumulative response so the UI can render text as it's produced.
    /// Returns the final, trimmed text so the caller can also cache it.
    @discardableResult
    func streamWeeklyReflection(
        summary: WeeklySummary,
        onPartial: @MainActor @escaping (String) -> Void
    ) async throws -> String {
        let instructions = """
        You are a calm, encouraging personal coach inside an iOS habit-tracking \
        app called Rhythm. Speak directly to the user in second person. Be warm \
        but not saccharine. Ground every observation in the data provided. Do \
        not invent activities the user did not log. If the user wrote any \
        reflections, you may echo a short phrase from them. Keep replies to \
        2–3 sentences. No headers, no bullet points, no emojis.
        """
        let prompt = Self.buildReflectionPrompt(from: summary)
        let result = try await stream(instructions: instructions, prompt: prompt, onPartial: onPartial)
        cache(reflection: result)
        return result
    }

    /// Stream a single concrete suggestion. Grounds its advice in the actual
    /// shape of the user's rhythms (names, beats, reminders) — not just the
    /// numerical data — so the suggestion can be structural as well as
    /// behavioural.
    @discardableResult
    func streamSuggestion(
        summary: WeeklySummary,
        onPartial: @MainActor @escaping (String) -> Void
    ) async throws -> String {
        let instructions = """
        You analyse the user's rhythms and suggest exactly ONE concrete \
        adjustment they could try this week. The adjustment can be \
        structural (add, remove or reorder a beat in a specific rhythm; \
        change a rhythm's period or reminder time) or behavioural \
        (anchor a struggling rhythm to an existing habit). Reference \
        rhythms and beats by name. Ground your advice in the data provided. \
        Keep it to one short sentence. Be specific. No emojis.
        """
        let prompt = Self.buildSuggestionPrompt(from: summary)
        let result = try await stream(instructions: instructions, prompt: prompt, onPartial: onPartial)
        cache(suggestion: result)
        return result
    }

    private func stream(
        instructions: String,
        prompt: String,
        onPartial: @MainActor @escaping (String) -> Void
    ) async throws -> String {
#if canImport(FoundationModels)
        guard isAvailable else { throw AICoachError.unavailable }
        do {
            let session = LanguageModelSession(instructions: instructions)
            // Try the streaming API first — it gives us progressive output.
            // If for any reason streaming isn't available, fall back to a
            // single non-streaming call.
            let stream = session.streamResponse(to: prompt)
            var latest = ""
            for try await partial in stream {
                // Each `partial` is a cumulative Snapshot whose `.content`
                // is the running response string. Reach in for the text and
                // trim trailing whitespace as it grows.
                latest = partial.content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                onPartial(latest)
            }
            return latest
        } catch {
            log.error("Stream failed, retrying non-streaming: \(error.localizedDescription)")
            // Best-effort retry without streaming.
            do {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: prompt)
                let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                onPartial(text)
                return text
            } catch let inner {
                log.error("Generation failed: \(inner.localizedDescription)")
                throw AICoachError.generationFailed("Coach is resting — try again in a moment.")
            }
        }
#else
        throw AICoachError.unavailable
#endif
    }

    // MARK: - Rule-based fallback

    nonisolated func ruleBasedReflection(summary: WeeklySummary) -> String {
        guard summary.totalScheduled > 0 else {
            return "No scheduled beats this week. Add a rhythm to start tracking your flow."
        }
        let pct = summary.completionPercent
        var sentences: [String] = []
        sentences.append("You completed \(pct)% of your scheduled beats this week (\(summary.totalCompleted)/\(summary.totalScheduled)).")
        if let best = summary.bestRhythmName {
            sentences.append("Your strongest rhythm was \(best).")
        }
        if let struggling = summary.strugglingRhythmName, struggling != summary.bestRhythmName {
            sentences.append("\(struggling) needed a little more attention.")
        }
        return sentences.joined(separator: " ")
    }

    nonisolated func ruleBasedSuggestion(summary: WeeklySummary) -> String {
        if let struggling = summary.strugglingRhythmName {
            return "This week, try anchoring \(struggling) to something you already do daily so it slots in without effort."
        }
        if summary.completionPercent >= 80 {
            return "You're flowing — try adding one small new beat to a rhythm to keep the momentum gentle."
        }
        return "Pick the single rhythm that matters most this week and protect its time before anything else."
    }

    // MARK: - Prompts

    private static func buildReflectionPrompt(from s: WeeklySummary) -> String {
        var lines: [String] = []
        lines.append("This week the user completed \(s.totalCompleted) of \(s.totalScheduled) scheduled beats (\(s.completionPercent)%).")
        if let best = s.bestRhythmName { lines.append("Best rhythm: \(best).") }
        if let struggling = s.strugglingRhythmName, struggling != s.bestRhythmName {
            lines.append("Struggling rhythm: \(struggling).")
        }
        lines.append("Longest active streak: \(s.longestActiveStreak) days.")
        for r in s.perRhythm {
            lines.append("- \(r.name): \(Int((r.completionRate * 100).rounded()))% completion, \(r.streak)-day streak.")
        }
        if !s.recentReflections.isEmpty {
            lines.append("")
            lines.append("Recent reflections the user wrote:")
            for r in s.recentReflections {
                let when = r.dayOffset == 0 ? "today" :
                           r.dayOffset == -1 ? "yesterday" :
                           "\(-r.dayOffset) days ago"
                lines.append("- (\(r.rhythmName), \(when)) \"\(r.text)\"")
            }
        }
        lines.append("")
        lines.append("Generate the weekly reflection.")
        return lines.joined(separator: "\n")
    }

    private static func buildSuggestionPrompt(from s: WeeklySummary) -> String {
        var lines: [String] = []
        lines.append("This week's data:")
        lines.append("- \(s.totalCompleted)/\(s.totalScheduled) beats completed (\(s.completionPercent)%).")
        for r in s.perRhythm {
            lines.append("- \(r.name): \(Int((r.completionRate * 100).rounded()))%, streak \(r.streak)d.")
        }
        if !s.rhythmStructure.isEmpty {
            lines.append("")
            lines.append("Rhythm structure:")
            for rs in s.rhythmStructure {
                let beatList = rs.beatTitles.joined(separator: ", ")
                let reminderText = rs.reminder.map { "reminder \($0)" } ?? "no reminder"
                lines.append("- \(rs.name) (\(rs.period), \(reminderText)): \(beatList)")
            }
        }
        if !s.recentReflections.isEmpty {
            lines.append("")
            lines.append("Recent reflections: \(s.recentReflections.map { "\"\($0.text)\"" }.joined(separator: " "))")
        }
        lines.append("")
        lines.append("Suggest exactly one concrete adjustment for next week.")
        return lines.joined(separator: "\n")
    }

    // MARK: - Caching

    private func cache(reflection: String) {
        lastReflection = reflection
        lastGeneratedAt = Date()
        UserDefaults.standard.set(reflection, forKey: reflectionKey)
        UserDefaults.standard.set(Self.currentWeekKey(), forKey: weekKey)
    }

    private func cache(suggestion: String) {
        lastSuggestion = suggestion
        lastGeneratedAt = Date()
        UserDefaults.standard.set(suggestion, forKey: suggestionKey)
    }

    private func loadCached() {
        let storedWeek = UserDefaults.standard.string(forKey: weekKey)
        if storedWeek == Self.currentWeekKey() {
            lastReflection = UserDefaults.standard.string(forKey: reflectionKey)
            lastSuggestion = UserDefaults.standard.string(forKey: suggestionKey)
        } else {
            lastReflection = nil
            lastSuggestion = nil
        }
    }

    /// Wipe every persisted AI artefact. Called by Settings → Reset and any
    /// time we want to invalidate stale model output (e.g. the user just
    /// disabled Apple Intelligence in iOS Settings).
    func clearCache() {
        lastReflection = nil
        lastSuggestion = nil
        lastGeneratedAt = nil
        UserDefaults.standard.removeObject(forKey: reflectionKey)
        UserDefaults.standard.removeObject(forKey: suggestionKey)
        UserDefaults.standard.removeObject(forKey: weekKey)
    }

    private static func currentWeekKey() -> String {
        let calendar = Calendar(identifier: .iso8601)
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return "\(comps.yearForWeekOfYear ?? 0)-W\(comps.weekOfYear ?? 0)"
    }
}
