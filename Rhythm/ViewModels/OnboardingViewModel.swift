//
//  OnboardingViewModel.swift
//  Rhythm
//
//  Drives the first-run onboarding flow. Tracks which templates the user has
//  selected and creates the corresponding rhythms via the persistence service
//  on completion.
//

import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    var page: Int = 0
    /// Pre-select the Morning Reset template so the primary CTA on the
    /// templates page reads "Add to my rhythm" rather than "Skip for now"
    /// when the user just keeps tapping Continue.
    var selectedTemplateIDs: Set<String> = ["morning-reset"]

    private let persistence: PersistenceService

    init(persistence: PersistenceService? = nil) {
        self.persistence = persistence ?? PersistenceService.shared
    }

    let templates: [RhythmTemplate] = RhythmTemplate.all

    var hasSelection: Bool { !selectedTemplateIDs.isEmpty }

    func toggle(_ template: RhythmTemplate) {
        if selectedTemplateIDs.contains(template.id) {
            selectedTemplateIDs.remove(template.id)
        } else {
            selectedTemplateIDs.insert(template.id)
        }
    }

    func isSelected(_ template: RhythmTemplate) -> Bool {
        selectedTemplateIDs.contains(template.id)
    }

    /// Materialise every selected template into a real rhythm. Safe to call
    /// with an empty selection — the user is allowed to skip.
    func finish() {
        let chosen = templates.filter { selectedTemplateIDs.contains($0.id) }
        for template in chosen {
            persistence.upsert(template.makeRhythm())
        }
    }
}
