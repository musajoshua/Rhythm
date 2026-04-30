//
//  Pricing.swift
//  Rhythm
//
//  Concept-level paywall. There is no real in-app purchase wired up — this
//  flag stands in for one so the freemium UX can be demonstrated.
//
//  Free tier:
//    - up to 2 rhythms
//    - up to 8 beats across all rhythms combined
//
//  Pro: caps removed, AI weekly summaries (already on for everyone in this
//  build but framed as Pro in the paywall card).
//

import Foundation

nonisolated enum Pricing {
    private static let key = "rhythm.isPremium"

    /// Hardcoded free-tier limits (spec §2.5).
    static let freeRhythmLimit = 2
    static let freeBeatLimit = 8

    /// Display strings shown in the paywall card.
    static let monthlyPrice = "€4.99 / month"
    static let yearlyPrice = "€47.99 / year"
    static let yearlySavingsBadge = "Save 20%"

    /// Whether the user currently has Pro. Driven by a UserDefaults flag —
    /// payment is intentionally not wired up.
    static var isPremium: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    /// True when adding another rhythm would push the free user over the cap.
    static func canAddRhythm(currentCount: Int) -> Bool {
        isPremium || currentCount < freeRhythmLimit
    }

    /// True when saving the proposed beat count would exceed the free cap.
    /// `proposedTotal` should be the sum of beats across all rhythms after
    /// the in-progress save lands.
    static func canSaveWithBeatTotal(_ proposedTotal: Int) -> Bool {
        isPremium || proposedTotal <= freeBeatLimit
    }

    /// Reset to the free tier — used by Settings → Reset All Data.
    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
