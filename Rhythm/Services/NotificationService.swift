//
//  NotificationService.swift
//  Rhythm
//

import Foundation
import UserNotifications
import OSLog

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let log = Logger(subsystem: "com.musajoshua.Rhythm", category: "Notifications")

    init() {}

    // MARK: - Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            log.info("Authorization granted: \(granted)")
            return granted
        } catch {
            log.error("Authorization request failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Only prompt if iOS hasn't decided yet. Useful when the user opts into
    /// a per-rhythm reminder before they've ever touched the global toggle.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await authorizationStatus()
        switch status {
        case .notDetermined:
            return await requestAuthorization()
        case .authorized, .provisional:
            return true
        default:
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Cancel and re-schedule notifications for the given rhythm. Drives off
    /// the rhythm's `reminderTime` and `activeDays`.
    func reschedule(for rhythm: Rhythm) async {
        await cancel(rhythmID: rhythm.id)
        guard let reminder = rhythm.reminderTime else { return }
        guard await isAuthorized() else { return }

        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminder)
        guard let hour = comps.hour, let minute = comps.minute else { return }

        for day in rhythm.activeDays {
            let request = makeRequest(for: rhythm, day: day, hour: hour, minute: minute)
            do {
                try await center.add(request)
            } catch {
                log.error("Failed to schedule \(request.identifier): \(error.localizedDescription)")
            }
        }
    }

    /// Cancel all pending notifications for a given rhythm.
    func cancel(rhythmID: UUID) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending
            .map { $0.identifier }
            .filter { $0.hasPrefix("rhythm-\(rhythmID.uuidString)-") }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// Cancel everything Rhythm has scheduled.
    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func isAuthorized() async -> Bool {
        let status = await authorizationStatus()
        return status == .authorized || status == .provisional
    }

    private func makeRequest(for rhythm: Rhythm, day: Weekday,
                             hour: Int, minute: Int) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Time for your \(rhythm.name)"
        let count = rhythm.trackingBeats.count
        content.body = "\(count) \(count == 1 ? "beat" : "beats") waiting."
        content.sound = .default

        // Calendar.weekday: 1 = Sunday … 7 = Saturday
        let calendarWeekday: Int = {
            switch day {
            case .sunday: return 1
            case .monday: return 2
            case .tuesday: return 3
            case .wednesday: return 4
            case .thursday: return 5
            case .friday: return 6
            case .saturday: return 7
            }
        }()

        var comps = DateComponents()
        comps.weekday = calendarWeekday
        comps.hour = hour
        comps.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let id = "rhythm-\(rhythm.id.uuidString)-\(day.rawValue)"
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
}
