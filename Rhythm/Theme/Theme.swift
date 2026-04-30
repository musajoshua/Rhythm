//
//  Theme.swift
//  Rhythm
//
//  Centralised color tokens. Calm, low-saturation, editorial palette inspired
//  by Apple Health and Apple Journal — not a noisy habit-tracker.
//

import SwiftUI

nonisolated enum Theme {

    // MARK: - Surfaces

    /// Page background. Slight warm tint in light mode for an editorial feel.
    static let background = Color(
        light: Color(hex: 0xFAF7F2),
        dark:  Color(hex: 0x101114)
    )

    /// Raised card surface.
    static let surface = Color(
        light: .white,
        dark:  Color(hex: 0x1A1B1F)
    )

    /// Subtle inner surface (insets, secondary panels).
    static let surfaceMuted = Color(
        light: Color(hex: 0xF1ECE3),
        dark:  Color(hex: 0x202126)
    )

    /// Hairline divider color.
    static let divider = Color(
        light: Color(hex: 0xE6E0D5),
        dark:  Color(hex: 0x2A2B30)
    )

    // MARK: - Text

    static let primaryText = Color(
        light: Color(hex: 0x1B1B1E),
        dark:  Color(hex: 0xF1EFEA)
    )

    static let secondaryText = Color(
        light: Color(hex: 0x6B6960),
        dark:  Color(hex: 0x9D9B93)
    )

    static let tertiaryText = Color(
        light: Color(hex: 0x9B988E),
        dark:  Color(hex: 0x6F6D66)
    )

    // MARK: - Accent

    /// Primary action accent. Muted sage, never neon.
    static let accent = Color(
        light: Color(hex: 0x6B8068),
        dark:  Color(hex: 0x9CB096)
    )

    /// Soft, low-contrast tint for accent backgrounds.
    static let accentSoft = Color(
        light: Color(hex: 0xE5EAE0),
        dark:  Color(hex: 0x2C342B)
    )

    /// Calm amber used for warning/streak emphasis.
    static let warning = Color(
        light: Color(hex: 0xC18A4D),
        dark:  Color(hex: 0xE2A872)
    )

    // MARK: - Period palette

    /// Foreground tint for a period chip / icon.
    static func tint(for period: RhythmPeriod) -> Color {
        switch period {
        case .morning: return Color(light: Color(hex: 0xC18A4D), dark: Color(hex: 0xE2A872))
        case .midday:  return Color(light: Color(hex: 0xB78A2A), dark: Color(hex: 0xD9B364))
        case .evening: return Color(light: Color(hex: 0x4F6F8E), dark: Color(hex: 0x8FAEC8))
        case .night:   return Color(light: Color(hex: 0x4B4F75), dark: Color(hex: 0x9498BE))
        case .anytime: return Color(light: Color(hex: 0x6B7280), dark: Color(hex: 0xAEB3BB))
        }
    }

    /// Background tint behind a period icon or chip — same hue, much lighter.
    static func softTint(for period: RhythmPeriod) -> Color {
        switch period {
        case .morning: return Color(light: Color(hex: 0xF6E9D5), dark: Color(hex: 0x3A2D1E))
        case .midday:  return Color(light: Color(hex: 0xF6EAC9), dark: Color(hex: 0x3A311A))
        case .evening: return Color(light: Color(hex: 0xDCE7F1), dark: Color(hex: 0x1F2A37))
        case .night:   return Color(light: Color(hex: 0xDADCEE), dark: Color(hex: 0x222538))
        case .anytime: return Color(light: Color(hex: 0xE7E9EC), dark: Color(hex: 0x252830))
        }
    }

    // MARK: - Legacy compatibility

    /// Kept so older code paths (and the editor's accent picker) keep working.
    static let primary = accent
    static let streak = accent
    static let textPrimary = primaryText
    static let textSecondary = secondaryText

    /// 6 selectable accents (legacy editor swatches). Maps loosely to periods.
    static let rhythmAccents: [String] = [
        "#6B8068", // sage / accent
        "#C18A4D", // morning
        "#B78A2A", // midday
        "#4F6F8E", // evening
        "#4B4F75", // night
        "#6B7280"  // anytime
    ]

    static let defaultAccentHex: String = rhythmAccents[0]

    // MARK: - Spacing & radii

    enum Spacing {
        static let screenPadding: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 16
        static let inline: CGFloat = 8
        static let tight: CGFloat = 4
    }

    enum Radius {
        static let card: CGFloat = 24
        static let pill: CGFloat = 999
        static let chip: CGFloat = 12
    }

    // MARK: - Motion

    /// Calm, brief default spring used for state changes.
    static let springAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.85)
    /// Eased ramp used for the progress ring fill.
    static let progressAnimation: Animation = .easeOut(duration: 0.45)
}

// MARK: - Color helpers

extension Color {
    /// Build a Color from a 0xRRGGBB hex literal.
    nonisolated init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    /// Build a Color from a "#RRGGBB" or "RRGGBB" string. Returns black on failure.
    nonisolated init(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else {
            self = .black
            return
        }
        self.init(hex: value)
    }

    /// Picks between two static palette colors based on the current trait
    /// collection at render time. Avoids needing one asset catalog per token.
    nonisolated init(light: Color, dark: Color) {
        self = Color(UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}
