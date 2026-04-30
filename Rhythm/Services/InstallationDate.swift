//
//  InstallationDate.swift
//  Rhythm
//
//  Tracks the date the app was first opened on this device. Used to anchor
//  the week window for new users so they don't see "last 7 days" of empty
//  history right after install.
//

import Foundation

nonisolated enum InstallationDate {
    private static let key = "rhythm.installDate"

    /// First-launch date. Records today the first time it's read; persists
    /// across launches in `UserDefaults`.
    nonisolated static var date: Date {
        if let stored = UserDefaults.standard.object(forKey: key) as? Date {
            return stored
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: key)
        return now
    }

    /// Wipe the recorded install date — called by Settings → Reset All Data.
    nonisolated static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
