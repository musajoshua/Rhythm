//
//  ProgressRing.swift
//  Rhythm
//

import SwiftUI

/// Circular progress indicator. Used for the Today momentum card and the
/// per-rhythm card progress.
struct ProgressRing: View {
    /// 0…1 fill amount. Values outside the range are clamped.
    let progress: Double
    var lineWidth: CGFloat = 8
    var trackColor: Color = Theme.divider
    var ringColor: Color = Theme.accent

    private var clamped: Double { max(0, min(1, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Theme.progressAnimation, value: clamped)
        }
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }
}

#Preview {
    HStack(spacing: 24) {
        ProgressRing(progress: 0.0).frame(width: 64, height: 64)
        ProgressRing(progress: 0.4).frame(width: 64, height: 64)
        ProgressRing(progress: 0.85).frame(width: 64, height: 64)
        ProgressRing(progress: 1.0).frame(width: 64, height: 64)
    }
    .padding()
    .background(Theme.background)
}
