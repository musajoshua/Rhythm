//
//  BeatRow.swift
//  Rhythm
//
//  One tappable row inside the rhythm detail screen. Tapping the entire row
//  toggles completion — no separate checkbox to aim for.
//

import SwiftUI

struct BeatRow: View {
    let beat: Beat
    let isCompleted: Bool
    let tint: Color
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isCompleted ? tint : Theme.divider, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if isCompleted {
                        Circle()
                            .fill(tint)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(beat.name)
                        .font(Typography.body)
                        .foregroundStyle(isCompleted ? Theme.tertiaryText : Theme.primaryText)
                        .strikethrough(isCompleted, color: Theme.tertiaryText)

                    if let details = beat.details, !details.isEmpty {
                        Text(details)
                            .font(Typography.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }

                    HStack(spacing: 8) {
                        if !beat.isRequired {
                            Label("Optional", systemImage: "circle.dashed")
                                .labelStyle(.titleAndIcon)
                                .font(Typography.caption)
                                .foregroundStyle(Theme.tertiaryText)
                        }
                        if let minutes = beat.durationMinutes {
                            Label("\(minutes) min", systemImage: "clock")
                                .labelStyle(.titleAndIcon)
                                .font(Typography.caption)
                                .foregroundStyle(Theme.tertiaryText)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
}

#Preview {
    VStack(spacing: 8) {
        BeatRow(
            beat: Beat(name: "Stretch", symbolName: "figure.flexibility",
                       durationMinutes: 10, order: 0, isRequired: true,
                       details: "Two minutes is enough."),
            isCompleted: false,
            tint: Theme.tint(for: .morning),
            onToggle: {}
        )
        BeatRow(
            beat: Beat(name: "Journal", symbolName: "book.closed", order: 1,
                       isRequired: false),
            isCompleted: true,
            tint: Theme.tint(for: .morning),
            onToggle: {}
        )
    }
    .padding()
    .background(Theme.background)
}
