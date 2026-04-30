//
//  EmptyStateView.swift
//  Rhythm
//

import SwiftUI

/// Reusable, calm empty state. Used everywhere a list might be empty.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.secondaryText)
                .padding(20)
                .background(Circle().fill(Theme.surfaceMuted))

            VStack(spacing: 6) {
                Text(title)
                    .font(Typography.title)
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let actionLabel, let action {
                PrimaryActionButton(title: actionLabel, systemImage: "plus", action: action)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        symbol: "sun.horizon",
        title: "Build your first rhythm",
        message: "Start with a single rhythm — Morning, Evening, or anything in between — and add a few small beats.",
        actionLabel: "Create a rhythm",
        action: {}
    )
    .background(Theme.background)
}
