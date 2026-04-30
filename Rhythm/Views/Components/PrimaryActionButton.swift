//
//  PrimaryActionButton.swift
//  Rhythm
//

import SwiftUI

/// The single "loud" button style in the app — calm enough to fit the
/// palette, but unambiguously the primary CTA on a screen.
struct PrimaryActionButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isEnabled ? Theme.accent : Theme.accent.opacity(0.4))
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryActionButton(title: "Create your first rhythm", systemImage: "plus", action: {})
        PrimaryActionButton(title: "Disabled", isEnabled: false, action: {})
    }
    .padding()
    .background(Theme.background)
}
