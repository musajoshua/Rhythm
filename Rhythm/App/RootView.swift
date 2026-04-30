//
//  RootView.swift
//  Rhythm
//
//  Top-level gating view. Decides between the onboarding flow and the main
//  tab shell, and ensures a clean blank slate the first time the user opens
//  the app on this device.
//

import SwiftUI

struct RootView: View {
    @Environment(PersistenceService.self) private var persistence
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootTabView()
            } else {
                OnboardingView(onFinish: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                })
            }
        }
        .preferredColorScheme(nil)
        .onAppear {
            ensureCleanStartIfNeeded()
        }
    }

    /// If the user hasn't finished onboarding yet but a stale database is
    /// already on disk (e.g. left over from a previous install), wipe it so
    /// they truly start blank. No-op once onboarding is complete.
    private func ensureCleanStartIfNeeded() {
        guard !hasCompletedOnboarding else { return }
        if !persistence.db.rhythms.isEmpty || !persistence.db.completions.isEmpty {
            persistence.resetAll()
        }
    }
}
