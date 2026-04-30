//
//  PaywallSheet.swift
//  Rhythm
//
//  Presented from the Today / Rhythms "+" buttons when the user is on the
//  free tier and tries to add past the cap. Same visual language as the
//  Settings → Rhythm Pro card.
//

import SwiftUI

struct PaywallSheet: View {
    let title: String
    let message: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        bullets
                        pricingBlock
                        buttons
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Rhythm Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 64, height: 64)
                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            Text(title)
                .font(Typography.display)
                .foregroundStyle(Theme.primaryText)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }

    private var bullets: some View {
        VStack(alignment: .leading, spacing: 8) {
            bullet("Unlimited rhythms and beats")
            bullet("On-device AI Coach insights")
            bullet("Weekly AI reflection summaries")
            bullet("Per-rhythm AI tips on demand")
            bullet("Richer charts and exports")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(Typography.body)
                .foregroundStyle(Theme.primaryText)
        }
    }

    private var pricingBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Pricing.monthlyPrice)
                    .font(Typography.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
            }
            HStack(spacing: 6) {
                Text(Pricing.yearlyPrice)
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.secondaryText)
                Text(Pricing.yearlySavingsBadge)
                    .font(Typography.caption.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.accentSoft))
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }

    private var buttons: some View {
        VStack(spacing: 8) {
            PrimaryActionButton(title: "Maybe later", systemImage: nil) {
                dismiss()
            }
            Text("Payment isn't wired up in this preview. The toggle in Settings → Rhythm Pro stands in for a real subscription.")
                .font(Typography.caption)
                .foregroundStyle(Theme.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
}

#Preview {
    PaywallSheet(
        title: "You've hit the free cap",
        message: "Free covers 2 rhythms and 8 beats. Upgrade to add more, and unlock the AI weekly summaries."
    )
}
