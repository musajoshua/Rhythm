//
//  RhythmsView.swift
//  Rhythm
//

import SwiftUI

struct RhythmsView: View {
    @Environment(PersistenceService.self) private var persistence
    @State private var viewModel: RhythmsViewModel?
    @State private var showingEditor = false
    @State private var pendingDeletion: Rhythm? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Rhythms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New rhythm")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RhythmsViewModel(persistence: persistence)
            }
        }
        .sheet(isPresented: $showingEditor) {
            RhythmEditorView(existingRhythm: nil)
        }
        .alert(
            "Delete \(pendingDeletion?.name ?? "rhythm")?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let id = pendingDeletion?.id {
                    viewModel?.delete(rhythmID: id)
                }
                pendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("This will remove the rhythm and all of its completion history.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if let vm = viewModel {
            if vm.rhythms.isEmpty {
                EmptyStateView(
                    symbol: "square.stack",
                    title: "No rhythms yet",
                    message: "Build a rhythm to get started.",
                    actionLabel: "Create a rhythm",
                    action: { showingEditor = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.rhythms) { rhythm in
                            NavigationLink {
                                RhythmDetailView(rhythm: rhythm)
                            } label: {
                                row(rhythm)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    pendingDeletion = rhythm
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
        } else {
            Color.clear
        }
    }

    private func row(_ rhythm: Rhythm) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.softTint(for: rhythm.period))
                    .frame(width: 56, height: 56)
                Image(systemName: rhythm.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.tint(for: rhythm.period))
            }

            VStack(alignment: .leading, spacing: 6) {
                PeriodChip(period: rhythm.period)
                Text(rhythm.name)
                    .font(Typography.title)
                    .foregroundStyle(Theme.primaryText)
                Text(metaLine(for: rhythm))
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.secondaryText)

                HStack(spacing: 4) {
                    ForEach(Weekday.allCases) { day in
                        Circle()
                            .fill(rhythm.activeDays.contains(day)
                                  ? Theme.tint(for: rhythm.period)
                                  : Theme.divider)
                            .frame(width: 6, height: 6)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .rhythmCard()
        .contentShape(Rectangle())
    }

    private func metaLine(for rhythm: Rhythm) -> String {
        let count = rhythm.beats.count
        let beatsLabel = "\(count) \(count == 1 ? "beat" : "beats")"
        if let reminder = rhythm.reminderText {
            return "\(beatsLabel) · \(reminder)"
        }
        return beatsLabel
    }
}

#Preview {
    RhythmsView()
        .environment(PersistenceService.preview)
}
