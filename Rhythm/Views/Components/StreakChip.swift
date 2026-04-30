//
//  StreakChip.swift
//  Rhythm
//

import SwiftUI

/// Calm streak pill. Streaks live as supporting detail in the new aesthetic;
/// momentum is the headline metric. We keep them around for the spec, but
/// styled softly.
struct StreakChip: View {
    enum Kind { case beat, rhythm }

    let count: Int
    let kind: Kind
    var tint: Color = Theme.warning

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame")
                .font(.caption2.weight(.semibold))
            Text(label)
                .font(Typography.caption)
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous).fill(tint.opacity(0.12))
        )
        .accessibilityLabel("\(count)-day \(kind == .beat ? "beat" : "rhythm") streak")
    }

    private var label: String {
        switch kind {
        case .beat:   return "\(count)d"
        case .rhythm: return "\(count)d rhythm"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StreakChip(count: 12, kind: .rhythm)
        StreakChip(count: 4, kind: .beat)
        StreakChip(count: 0, kind: .beat)
    }
    .padding()
    .background(Theme.background)
}
