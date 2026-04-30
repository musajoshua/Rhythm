//
//  AICoachCard.swift
//  Rhythm
//

import SwiftUI

struct AICoachCard: View {
    let title: String
    let message: String?
    let isGenerating: Bool
    var onRefresh: (() -> Void)? = nil
    var cooldownRemaining: Int = 0
    var availability: AICoachService.AvailabilityStatus = .available
    var showAIFooter: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                    Text(title)
                        .font(Typography.headline)
                        .foregroundStyle(Theme.primaryText)
                }
                Spacer()
                if let onRefresh {
                    Button(action: onRefresh) {
                        if isGenerating {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .disabled(isGenerating || cooldownRemaining > 0)
                    .accessibilityLabel(cooldownRemaining > 0
                                        ? "Refresh in \(cooldownRemaining) seconds"
                                        : "Refresh")
                }
            }

            if let message, !message.isEmpty {
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else if isGenerating {
                Text("Reflecting on your week…")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                Text("Tap refresh to generate.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
            }

            if showAIFooter {
                Text(footerText)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }

    private var footerText: String {
        switch availability {
        case .available:
            return "Generated on-device with Apple Intelligence"
        case .unavailableAppleIntelligenceOff:
            return "Apple Intelligence is off — showing rule-based summary"
        case .unavailableDeviceUnsupported:
            return "Device doesn't support Apple Intelligence — showing rule-based summary"
        case .unavailableModelNotReady:
            return "Model still preparing — showing rule-based summary"
        }
    }
}

#Preview {
    AICoachCard(
        title: "Your weekly reflection",
        message: "You held your Morning Rhythm together six days this week — the strongest you've been all month. Wind-Down still slips on weekends; that's the next quiet edge to soften.",
        isGenerating: false,
        onRefresh: {},
        cooldownRemaining: 0,
        availability: .available
    )
    .padding()
    .background(Theme.background)
}
