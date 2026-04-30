//
//  RhythmApp.swift
//  Rhythm
//

import SwiftUI

@main
struct RhythmApp: App {
    @State private var persistence = PersistenceService.shared
    @State private var aiCoach = AICoachService.shared

    init() {
        PersistenceService.shared.load()
        // Stamp first-launch date if it hasn't been recorded yet so the
        // Insights "Your first 7 days" window starts from now.
        _ = InstallationDate.date
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(persistence)
                .environment(aiCoach)
                .tint(Theme.accent)
        }
    }
}
