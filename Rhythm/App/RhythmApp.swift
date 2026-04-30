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
