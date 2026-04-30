//
//  SettingsViewModel.swift
//  Rhythm
//

import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class SettingsViewModel {
    private let persistence: PersistenceService
    private let notifications: NotificationService

    var notificationsEnabled: Bool = false
    var notificationsAuthStatus: UNAuthorizationStatus = .notDetermined

    init(persistence: PersistenceService? = nil,
         notifications: NotificationService? = nil) {
        self.persistence = persistence ?? PersistenceService.shared
        self.notifications = notifications ?? NotificationService.shared
    }

    var rhythmCount: Int { persistence.db.rhythms.count }
    var beatCount: Int { persistence.db.rhythms.reduce(0) { $0 + $1.beats.count } }
    var completionCount: Int { persistence.db.completions.count }

    var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    func refreshAuthStatus() async {
        notificationsAuthStatus = await notifications.authorizationStatus()
        notificationsEnabled = notificationsAuthStatus == .authorized
            || notificationsAuthStatus == .provisional
    }

    func setNotifications(enabled: Bool) async {
        if enabled {
            let granted = await notifications.requestAuthorization()
            notificationsEnabled = granted
            if granted {
                // Re-schedule everything based on current rhythms.
                // Re-schedule any rhythm that has a reminder time set.
                for rhythm in persistence.db.rhythms where rhythm.reminderTime != nil {
                    await notifications.reschedule(for: rhythm)
                }
            }
        } else {
            await notifications.cancelAll()
            notificationsEnabled = false
        }
        await refreshAuthStatus()
    }

    func resetAll() async {
        await notifications.cancelAll()
        persistence.resetAll()
        // Wipe the AI cache so we don't keep stale reflections from before.
        AICoachService.shared.clearCache()
        // Bring the user back to onboarding so the next launch feels fresh.
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
    }

    func insertSampleData() {
        persistence.replace(with: SampleData.makeSampleDatabase())
    }
}
