//
//  InsightsView.swift
//  Rhythm
//

import SwiftUI

struct InsightsView: View {
    @Environment(PersistenceService.self) private var persistence
    @Environment(AICoachService.self) private var aiCoach
    @State private var viewModel: InsightsViewModel?
    /// Drives a 1Hz tick so the cooldown countdown re-renders.
    @State private var tick: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Insights")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = InsightsViewModel(persistence: persistence, aiCoach: aiCoach)
            }
            Task { await viewModel?.generateIfNeeded() }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                tick &+= 1
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let vm = viewModel {
            if persistence.db.rhythms.isEmpty {
                EmptyStateView(
                    symbol: "chart.line.uptrend.xyaxis",
                    title: "Nothing to show yet",
                    message: "Once you create a rhythm and complete a few beats, your momentum will appear here."
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        completionCard(vm: vm)
                        WeeklyChartView(data: vm.perDayRatios)
                        strongestRhythmCard(vm: vm)
                        weekTotalsRow(vm: vm)
                        aiSection(vm: vm)
                        reflectionsCard(vm: vm)
                        perRhythmCard(vm: vm)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
            }
        } else {
            Color.clear
        }
    }

    // MARK: - Sections

    private func completionCard(vm: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Last 7 days", subtitle: "Average completion across all rhythms")
            HStack(spacing: 24) {
                ZStack {
                    ProgressRing(
                        progress: vm.weeklyPercentage,
                        lineWidth: 12,
                        ringColor: Theme.accent
                    )
                    .frame(width: 120, height: 120)
                    VStack(spacing: 2) {
                        Text("\(Int((vm.weeklyPercentage * 100).rounded()))")
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.primaryText)
                        Text("PERCENT")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.tertiaryText)
                            .tracking(1)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(vm.momentumLevel.displayName)
                        .font(Typography.title)
                        .foregroundStyle(Theme.primaryText)
                    Text(vm.momentumLevel.description)
                        .font(Typography.footnote)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .rhythmCard()
    }

    private func strongestRhythmCard(vm: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Strongest rhythm")
            if let best = vm.strongestRhythm {
                let rhythm = best.rhythm
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.softTint(for: rhythm.period))
                            .frame(width: 56, height: 56)
                        Image(systemName: rhythm.iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.tint(for: rhythm.period))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rhythm.name)
                            .font(Typography.title)
                            .foregroundStyle(Theme.primaryText)
                        Text("\(Int((best.rate * 100).rounded()))% over the last 7 days")
                            .font(Typography.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                Text("Complete beats in a few rhythms to see which one you're holding most steady.")
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }

    private func weekTotalsRow(vm: InsightsViewModel) -> some View {
        HStack(spacing: 12) {
            StatTile(value: "\(vm.totalCompletionsThisWeek)",
                     label: "Beats", caption: "Completed this week")
            StatTile(value: "\(vm.bestBeatStreak)",
                     label: "Best", caption: "Beat streak")
            StatTile(value: "\(vm.bestRhythmStreak)",
                     label: "Best", caption: "Rhythm streak")
        }
    }

    private func aiSection(vm: InsightsViewModel) -> some View {
        VStack(spacing: 12) {
            // A read of `tick` so the view recomputes the cooldown each second.
            let _ = tick

            AICoachCard(
                title: "Your weekly reflection",
                message: vm.reflectionText,
                isGenerating: vm.isGenerating,
                onRefresh: { Task { await vm.generate() } },
                cooldownRemaining: vm.refreshCooldownRemaining,
                availability: vm.aiAvailability
            )

            AICoachCard(
                title: "One thing to try this week",
                message: vm.suggestionText,
                isGenerating: vm.isGenerating,
                onRefresh: nil,
                availability: vm.aiAvailability,
                showAIFooter: false
            )
        }
    }

    private func reflectionsCard(vm: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Recent reflections")
            if vm.recentReflections.isEmpty {
                Text("Reflections you write on a rhythm this week will appear here.")
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.recentReflections, id: \.reflection.id) { entry in
                        reflectionRow(entry: entry)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }

    private func reflectionRow(entry: (reflection: DailyReflection, rhythm: Rhythm)) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                PeriodChip(period: entry.rhythm.period)
                Text(entry.rhythm.name)
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.secondaryText)
                Spacer(minLength: 0)
                Text(entry.reflection.day, format: .dateTime.month().day())
                    .font(Typography.caption)
                    .foregroundStyle(Theme.tertiaryText)
            }
            Text(entry.reflection.text)
                .font(Typography.body)
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surfaceMuted)
        )
    }

    private func perRhythmCard(vm: InsightsViewModel) -> some View {
        // Snapshot the computed breakdown once per render. Re-reading
        // `vm.perRhythmBreakdown` inside the ForEach closure would recompute
        // it each time and could race with data resets, producing an
        // "Index out of range" crash when the underlying rhythms array
        // shrinks mid-render.
        let breakdown = vm.perRhythmBreakdown
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Per-rhythm breakdown")
            VStack(spacing: 0) {
                ForEach(Array(breakdown.enumerated()), id: \.element.rhythm.id) { idx, row in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.softTint(for: row.rhythm.period))
                                .frame(width: 36, height: 36)
                            Image(systemName: row.rhythm.iconName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.tint(for: row.rhythm.period))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.rhythm.name)
                                .font(Typography.body.weight(.semibold))
                                .foregroundStyle(Theme.primaryText)
                            Text("\(Int((row.completionRate * 100).rounded()))% this week")
                                .font(Typography.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        Spacer(minLength: 0)
                        if row.streak > 0 {
                            StreakChip(count: row.streak, kind: .rhythm,
                                       tint: Theme.tint(for: row.rhythm.period))
                        }
                    }
                    .padding(.vertical, 10)
                    if idx < breakdown.count - 1 {
                        Rectangle()
                            .fill(Theme.divider)
                            .frame(height: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }
}

#Preview {
    InsightsView()
        .environment(PersistenceService.preview)
        .environment(AICoachService.shared)
}
