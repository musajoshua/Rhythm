//
//  MomentumCard.swift
//  Rhythm
//
//  Hero card on Today. Communicates "how the last week has felt" without
//  collapsing into streak-counting habit-tracker territory. Replaces the
//  earlier Flow Wave per the Rhythm2 design language.
//

import SwiftUI

/// Compact summary used by the momentum card.
struct MomentumSummary: Hashable {
    /// 0…1 average completion across the last 7 days.
    let percentage: Double
    /// Per-day completion ratios, oldest first. Length should be 7.
    let perDay: [Double]
    let level: MomentumLevel
}

struct MomentumCard: View {
    let summary: MomentumSummary
    /// 0…1 — share of *today's* scheduled beats already completed.
    let todayProgress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Momentum")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .textCase(.uppercase)
                        .tracking(1.2)
                    Text(summary.level.displayName)
                        .font(Typography.display)
                        .foregroundStyle(Theme.primaryText)
                }
                Spacer()
                ZStack {
                    ProgressRing(progress: todayProgress, lineWidth: 8, ringColor: Theme.accent)
                        .frame(width: 64, height: 64)
                    Text("\(Int((todayProgress * 100).rounded()))%")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.primaryText)
                }
            }

            Text(summary.level.description)
                .font(Typography.body)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 4) {
                ForEach(summary.perDay.indices, id: \.self) { idx in
                    DayPip(value: summary.perDay[idx])
                }
            }
        }
        .rhythmCard()
    }
}

#Preview {
    let summary = MomentumSummary(
        percentage: 0.62,
        perDay: [0.4, 0.7, 0.1, 0.9, 0.6, 0.8, 0.5],
        level: .strong
    )
    return MomentumCard(summary: summary, todayProgress: 0.5)
        .padding()
        .background(Theme.background)
}
