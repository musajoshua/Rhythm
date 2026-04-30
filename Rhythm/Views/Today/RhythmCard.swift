//
//  RhythmCard.swift
//  Rhythm
//

import SwiftUI

struct RhythmCard: View {
    let rhythm: Rhythm
    let progress: Double
    let completedCount: Int
    /// Current rhythm-level streak (consecutive scheduled days where every
    /// required beat was completed). Surfaced as a small chip — momentum is
    /// still the headline metric on the Today screen.
    var streak: Int = 0

    private var tint: Color { Theme.tint(for: rhythm.period) }
    private var softTint: Color { Theme.softTint(for: rhythm.period) }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    PeriodChip(period: rhythm.period)
                    if streak > 0 {
                        StreakChip(count: streak, kind: .rhythm, tint: tint)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(rhythm.name)
                        .font(Typography.title)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                    Text(progressSummary)
                        .font(Typography.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }

                if let reminder = rhythm.reminderTime {
                    HStack(spacing: 6) {
                        Image(systemName: "bell")
                            .font(.caption2)
                        Text(reminder, format: .dateTime.hour().minute())
                            .font(Typography.caption)
                    }
                    .foregroundStyle(Theme.tertiaryText)
                }
            }

            Spacer(minLength: 0)

            ZStack {
                Circle().fill(softTint).frame(width: 64, height: 64)
                ProgressRing(
                    progress: progress,
                    lineWidth: 6,
                    trackColor: softTint,
                    ringColor: tint
                )
                .frame(width: 64, height: 64)
                Image(systemName: rhythm.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .rhythmCard()
        .contentShape(Rectangle())
    }

    private var progressSummary: String {
        let total = rhythm.trackingBeats.count
        guard total > 0 else { return "Add a beat to start" }
        let completedTracking = Int((progress * Double(total)).rounded())
        if completedCount == 0 {
            return "\(total) \(total == 1 ? "beat" : "beats") · ready when you are"
        }
        return "\(completedTracking) of \(total) complete"
    }
}

#Preview {
    let rhythm = SampleData.makeSampleDatabase().rhythms[0]
    return VStack {
        RhythmCard(rhythm: rhythm, progress: 0.5, completedCount: 1, streak: 6)
        RhythmCard(rhythm: rhythm, progress: 0.0, completedCount: 0, streak: 0)
    }
    .padding()
    .background(Theme.background)
}
