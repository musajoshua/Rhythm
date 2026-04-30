//
//  Typography.swift
//  Rhythm
//
//  Typographic scale. The app uses serif for hero headings (editorial,
//  Journal-like) and the system rounded face for everything else.
//

import SwiftUI

nonisolated enum Typography {
    /// Big display headings (greeting, screen titles).
    static let display: Font = .system(.largeTitle, design: .serif, weight: .semibold)
    /// Card-level title.
    static let title: Font = .system(.title3, design: .rounded, weight: .semibold)
    /// Section titles inside a card.
    static let headline: Font = .system(.headline, design: .rounded, weight: .semibold)
    /// Body copy for descriptive text.
    static let body: Font = .system(.body, design: .rounded, weight: .regular)
    /// Smaller secondary copy (captions, subtitles).
    static let footnote: Font = .system(.footnote, design: .rounded, weight: .medium)
    /// Subtle metadata (timestamps, period chips).
    static let caption: Font = .system(.caption, design: .rounded, weight: .medium)
    /// Display-style number for stat values.
    static let statNumber: Font = .system(size: 28, weight: .semibold, design: .rounded)
}
