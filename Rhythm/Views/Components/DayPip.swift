//
//  DayPip.swift
//  Rhythm
//

import SwiftUI

/// Tiny vertical bar representing one day's completion. A row of seven gives
/// a glanceable trend without leaning on the Charts framework.
struct DayPip: View {
    /// 0…1 normalised completion for the day.
    let value: Double
    var tint: Color = Theme.accent

    var body: some View {
        GeometryReader { proxy in
            let height = max(4, proxy.size.height * max(0, min(1, value)))
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Theme.divider)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(tint.opacity(0.85))
                    .frame(height: height)
            }
        }
        .frame(height: 32)
    }
}

/// Larger trend bar used on Insights — same idea, with room for a weekday label.
struct TrendBar: View {
    let value: Double
    var tint: Color = Theme.accent

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.divider)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint)
                    .frame(height: max(6, proxy.size.height * max(0, min(1, value))))
            }
        }
    }
}

#Preview {
    HStack(spacing: 6) {
        ForEach(0..<7) { i in
            DayPip(value: Double(i) / 6.0)
        }
    }
    .padding()
    .background(Theme.background)
}
