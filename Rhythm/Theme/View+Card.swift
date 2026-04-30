//
//  View+Card.swift
//  Rhythm
//
//  The default card chrome used everywhere a "block" of content lives on
//  the page. 24pt rounded surface, generous padding, and a soft shadow.
//

import SwiftUI

extension View {
    /// Wrap the view in the app's default card chrome.
    func rhythmCard(padding: CGFloat = Theme.Spacing.cardPadding) -> some View {
        modifier(RhythmCardModifier(padding: padding))
    }
}

private struct RhythmCardModifier: ViewModifier {
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Theme.surface)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 6)
    }
}
