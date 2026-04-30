//
//  PeriodChip.swift
//  Rhythm
//

import SwiftUI

/// Small pill labelling a rhythm's period of day. Sits on top of every card.
struct PeriodChip: View {
    let period: RhythmPeriod

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: period.defaultIconName)
                .font(.caption2.weight(.semibold))
            Text(period.displayName)
                .font(Typography.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(Theme.tint(for: period))
        .background(
            Capsule().fill(Theme.softTint(for: period))
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        ForEach(RhythmPeriod.allCases) { p in PeriodChip(period: p) }
    }
    .padding()
    .background(Theme.background)
}
