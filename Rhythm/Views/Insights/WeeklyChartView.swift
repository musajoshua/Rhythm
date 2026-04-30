//
//  WeeklyChartView.swift
//  Rhythm
//
//  7-day completion bars. Custom shapes (no Charts framework) so the
//  rendering matches the rest of the app's calm, editorial aesthetic.
//

import SwiftUI

struct WeeklyChartView: View {
    /// Per-day completion ratios + the date for the weekday label, oldest first.
    let data: [(date: Date, value: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(data.indices, id: \.self) { idx in
                    VStack(spacing: 8) {
                        TrendBar(value: data[idx].value)
                            .frame(height: 96)
                        Text(weekday(for: data[idx].date))
                            .font(Typography.caption)
                            .foregroundStyle(Theme.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }

    private func weekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }
}

#Preview {
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    let sample = (0..<7).reversed().map { offset -> (Date, Double) in
        let day = cal.date(byAdding: .day, value: -offset, to: today)!
        return (day, Double.random(in: 0...1))
    }
    return WeeklyChartView(data: sample.map { ($0.0, $0.1) })
        .padding()
        .background(Theme.background)
}
