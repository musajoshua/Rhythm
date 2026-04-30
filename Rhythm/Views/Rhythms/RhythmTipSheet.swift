//
//  RhythmTipSheet.swift
//  Rhythm
//
//  Presents an Apple-Intelligence-generated tip about a single rhythm.
//  Pushed from the rhythm detail screen via the sparkles button.
//

import SwiftUI

struct RhythmTipSheet: View {
    let rhythm: Rhythm

    @Environment(\.dismiss) private var dismiss
    @Environment(PersistenceService.self) private var persistence
    @Environment(AICoachService.self) private var aiCoach

    @State private var tip: String = ""
    @State private var isGenerating = false
    @State private var hasGeneratedOnce = false

    private var calendar: Calendar { .current }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        tipCard
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("AI tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            aiCoach.refreshAvailability()
            if !hasGeneratedOnce {
                Task { await generate() }
            }
        }
    }

    // MARK: - UI

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.softTint(for: rhythm.period))
                    .frame(width: 56, height: 56)
                Image(systemName: rhythm.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.tint(for: rhythm.period))
            }
            VStack(alignment: .leading, spacing: 4) {
                PeriodChip(period: rhythm.period)
                Text(rhythm.name)
                    .font(Typography.title)
                    .foregroundStyle(Theme.primaryText)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.accent)
                    Text("Tip for \(rhythm.name)")
                        .font(Typography.headline)
                }
                Spacer()
                Button {
                    Task { await generate() }
                } label: {
                    if isGenerating {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .disabled(isGenerating)
                .accessibilityLabel("Refresh")
            }
            if !tip.isEmpty {
                Text(tip)
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else if isGenerating {
                Text("Looking at this rhythm…")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                Text("Tap refresh to generate a tip.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
            }
            Text(footerText)
                .font(Typography.caption)
                .foregroundStyle(Theme.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }

    private var footerText: String {
        switch aiCoach.availability {
        case .available:                       return "Generated on-device with Apple Intelligence"
        case .unavailableAppleIntelligenceOff: return "Apple Intelligence is off — showing rule-based tip"
        case .unavailableDeviceUnsupported:    return "Device doesn't support Apple Intelligence — showing rule-based tip"
        case .unavailableModelNotReady:        return "Model still preparing — showing rule-based tip"
        }
    }

    // MARK: - Generation

    private func generate() async {
        isGenerating = true
        defer {
            isGenerating = false
            hasGeneratedOnce = true
        }
        let context = buildContext()
        if !aiCoach.isAvailable {
            tip = aiCoach.ruleBasedRhythmTip(context: context)
            return
        }
        tip = ""
        do {
            tip = try await aiCoach.streamRhythmTip(context: context) { partial in
                tip = partial
            }
        } catch {
            if tip.isEmpty {
                tip = aiCoach.ruleBasedRhythmTip(context: context)
            }
        }
    }

    private func buildContext() -> RhythmTipContext {
        let beatTitles = rhythm.sortedBeats.map { beat -> String in
            let suffix = beat.isRequired ? "" : " (opt)"
            return beat.name + suffix
        }
        let reminder: String? = {
            guard let r = rhythm.reminderTime else { return nil }
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: r)
        }()
        // Rolling 7-day completion rate over required beats only.
        let today = calendar.startOfDay(for: .now)
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        let scheduledDays = days.filter { rhythm.isScheduled(on: $0, calendar: calendar) }
        let perDay = max(rhythm.trackingBeats.count, 1)
        let scheduledTotal = scheduledDays.count * perDay
        let completedTotal = scheduledDays.reduce(0) { acc, d in
            acc + rhythm.trackingBeats.filter {
                persistence.isCompleted(beatID: $0.id, on: d, calendar: calendar)
            }.count
        }
        let rate: Double = scheduledTotal == 0 ? 0 : Double(completedTotal) / Double(scheduledTotal)
        let streak = StreakCalculator.rhythmStreak(
            for: rhythm,
            completions: persistence.db.completions,
            calendar: calendar
        ).current
        let reflections = persistence.recentReflections(for: rhythm.id, limit: 3).map(\.text)

        return RhythmTipContext(
            name: rhythm.name,
            period: rhythm.period.displayName,
            beatTitles: beatTitles,
            reminder: reminder,
            last7DaysCompletionRate: rate,
            currentStreak: streak,
            recentReflections: reflections
        )
    }
}

#Preview {
    RhythmTipSheet(rhythm: SampleData.makeSampleDatabase().rhythms[0])
        .environment(PersistenceService.preview)
        .environment(AICoachService.shared)
}
