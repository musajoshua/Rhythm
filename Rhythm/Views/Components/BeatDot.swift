//
//  BeatDot.swift
//  Rhythm
//

import SwiftUI

/// Small outlined / filled circle representing a beat's daily completion state.
/// Used in the compact dot row on the rhythm card.
struct BeatDot: View {
    let isCompleted: Bool
    var tint: Color = Theme.accent
    var size: CGFloat = 14

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(tint.opacity(isCompleted ? 0 : 0.6), lineWidth: 1.5)
            Circle()
                .fill(tint)
                .opacity(isCompleted ? 1 : 0)
                .scaleEffect(isCompleted ? 1 : 0.6)
        }
        .frame(width: size, height: size)
        .animation(Theme.springAnimation, value: isCompleted)
        .accessibilityLabel(isCompleted ? "Completed" : "Pending")
    }
}

#Preview {
    HStack(spacing: 12) {
        BeatDot(isCompleted: true)
        BeatDot(isCompleted: false)
        BeatDot(isCompleted: true, tint: Theme.tint(for: .morning), size: 18)
    }
    .padding()
    .background(Theme.background)
}
