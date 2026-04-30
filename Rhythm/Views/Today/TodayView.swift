//
//  TodayView.swift
//  Rhythm
//

import SwiftUI

struct TodayView: View {
    @Environment(PersistenceService.self) private var persistence
    @State private var viewModel: TodayViewModel?
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Theme.background.ignoresSafeArea()
                if let vm = viewModel {
                    contentView(vm: vm)
                        .safeAreaInset(edge: .top) { topBar }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TodayViewModel(persistence: persistence)
            }
        }
        .sheet(isPresented: $showingEditor) {
            RhythmEditorView(existingRhythm: nil)
        }
    }

    // MARK: - Layout

    private var topBar: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel?.greeting ?? "")
                    .font(Typography.display)
                    .foregroundStyle(Theme.primaryText)
                Text(viewModel?.dateLine ?? "")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Button {
                showingEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                    .padding(12)
                    .background(Circle().fill(Theme.surface))
                    .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New rhythm")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Theme.background)
    }

    @ViewBuilder
    private func contentView(vm: TodayViewModel) -> some View {
        if persistence.db.rhythms.isEmpty {
            EmptyStateView(
                symbol: "sun.horizon",
                title: "Build your first rhythm",
                message: "Start with a single rhythm — Morning, Evening, or anything in between — and add a few small beats.",
                actionLabel: "Create a rhythm",
                action: { showingEditor = true }
            )
            .padding(.top, 40)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    MomentumCard(
                        summary: vm.momentumSummary,
                        todayProgress: vm.todayProgress
                    )
                    .padding(.horizontal, 20)

                    SectionHeader("Today", subtitle: "Your rhythm for the day")
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    if vm.rhythmsScheduledToday.isEmpty {
                        quietDayCard
                            .padding(.horizontal, 20)
                    } else {
                        ForEach(vm.rhythmsScheduledToday) { rhythm in
                            NavigationLink {
                                RhythmDetailView(rhythm: rhythm)
                            } label: {
                                RhythmCard(
                                    rhythm: rhythm,
                                    progress: vm.progress(for: rhythm),
                                    completedCount: vm.completedCount(for: rhythm),
                                    streak: vm.rhythmStreak(for: rhythm)
                                )
                                .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(
                                TapGesture().onEnded { triggerSelectionHaptic() }
                            )
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func triggerSelectionHaptic() {
#if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
    }

    private var quietDayCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A quiet day")
                .font(Typography.title)
                .foregroundStyle(Theme.primaryText)
            Text("Nothing scheduled today. Use the + above to add a new rhythm whenever you're ready.")
                .font(Typography.body)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rhythmCard()
    }
}

#Preview {
    TodayView()
        .environment(PersistenceService.preview)
}
