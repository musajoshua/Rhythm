//
//  StatTile.swift
//  Rhythm
//

import SwiftUI

/// Small editorial stat tile. Tracking-uppercase caption above the value.
/// Always reserves space for a caption line so a row of tiles ends up the
/// same height even when one of them has no caption.
struct StatTile: View {
    let value: String
    let label: String
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.tertiaryText)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(value)
                .font(Typography.statNumber)
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            // Reserve 2 lines for the caption regardless of whether one is set
            // so siblings in an HStack share the same height.
            Text(caption ?? " ")
                .font(Typography.footnote)
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .rhythmCard()
    }
}

#Preview {
    HStack(spacing: 12) {
        StatTile(value: "07:00", label: "Window")
        StatTile(value: "12", label: "Streak", caption: "1 grace used")
        StatTile(value: "12", label: "Best", caption: "All time")
    }
    .padding()
    .background(Theme.background)
}
