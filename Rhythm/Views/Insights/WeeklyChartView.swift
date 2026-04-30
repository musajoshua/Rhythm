//
//  WeeklyChartView.swift
//  Rhythm
//
//  7-day completion bars rendered with the SwiftUI Charts framework, styled
//  to match the rest of the editorial design system. Uses the project's
//  rounded mark corners + accent gradient so the chart stays visually
//  cohesive with the custom shapes elsewhere.
//

import SwiftUI
import Charts

struct WeeklyChartView: View {
    /// Per-day completion ratios + the date for the weekday label, oldest first.
    let data: [(date: Date, value: Double)]

    var body: some View {
        Chart(data, id: \.date) { item in
            BarMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Completion", item.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Theme.accent, Theme.accent.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(6)
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 0.5, 1]) { value in
                AxisGridLine().foregroundStyle(Theme.divider)
                AxisValueLabel {
                    if let pct = value.as(Double.self) {
                        Text("\(Int(pct * 100))%")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.tertiaryText)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .foregroundStyle(Theme.tertiaryText)
                    .font(Typography.caption)
            }
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
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
