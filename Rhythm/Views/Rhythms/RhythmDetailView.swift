//
//  RhythmDetailView.swift
//  Rhythm
//
//  Pushed when the user taps a rhythm on Today (or in the Rhythms list).
//  Shows a hero card, the beats with tap-to-toggle completion, and an Edit
//  button in the toolbar.
//

import SwiftUI

struct RhythmDetailView: View {
    let rhythm: Rhythm

    @Environment(PersistenceService.self) private var persistence
    @State private var showingEditor = false
    @State private var pulseBeatID: UUID? = nil
    @State private var reflectionDraft: String = ""
    @State private var didLoadReflection = false
    @State private var reflectionLastSavedAt: Date? = nil
    @FocusState private var reflectionFocused: Bool

    /// Always read the latest copy of the rhythm out of persistence — the user
    /// may have edited it and we want the detail screen to reflect that
    /// without re-pushing.
    private var current: Rhythm {
        persistence.db.rhythms.first(where: { $0.id == rhythm.id }) ?? rhythm
    }
    private var tint: Color { Theme.tint(for: current.period) }
    private var softTint: Color { Theme.softTint(for: current.period) }

    private var today: Date { Calendar.current.startOfDay(for: .now) }
    private var trackingTotal: Int { max(current.trackingBeats.count, 1) }
    private var trackingCompleted: Int {
        current.trackingBeats.filter {
            persistence.isCompleted(beatID: $0.id, on: today)
        }.count
    }
    private var progress: Double {
        guard !current.trackingBeats.isEmpty else { return 0 }
        return Double(trackingCompleted) / Double(current.trackingBeats.count)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    beatsList
                    reflectionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(current.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Edit rhythm")
            }
        }
        .sheet(isPresented: $showingEditor) {
            RhythmEditorView(existingRhythm: current)
        }
        .onAppear { loadReflectionIfNeeded() }
        .onDisappear { saveReflection() }
        .onChange(of: reflectionFocused) { _, isFocused in
            if !isFocused { saveReflection() }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle().fill(softTint).frame(width: 72, height: 72)
                    Image(systemName: current.iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    PeriodChip(period: current.period)
                    Text(current.name)
                        .font(Typography.display)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                    if let notes = current.notes, !notes.isEmpty {
                        Text(notes)
                            .font(Typography.body)
                            .foregroundStyle(Theme.secondaryText)
                    } else {
                        Text(current.period.tagline)
                            .font(Typography.body)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(Theme.divider)
                .frame(height: 1)

            // ViewThatFits gracefully wraps to a 2-row Grid when the user's
            // Dynamic Type setting blows the inline row out of the available
            // width. Keeps the editorial look at default sizes and stays
            // legible at XXL.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    statTiles
                    Spacer(minLength: 0)
                }
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                    GridRow { statTiles }
                }
            }
        }
        .rhythmCard()
    }

    @ViewBuilder
    private var statTiles: some View {
        miniStat(title: "Today", value: "\(trackingCompleted)/\(trackingTotal)")
        miniStat(title: "Progress", value: "\(Int((progress * 100).rounded()))%")
        if let reminder = current.reminderTime {
            miniStat(title: "Reminder",
                     value: reminder.formatted(.dateTime.hour().minute()))
        } else {
            miniStat(title: "Reminder", value: "—")
        }
    }

    /// Mini inline stat tile — same layout for every column so the row aligns.
    private func miniStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(Theme.tertiaryText)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(value)
                .font(Typography.headline)
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Beats

    @ViewBuilder
    private var beatsList: some View {
        if current.sortedBeats.isEmpty {
            EmptyStateView(
                symbol: "list.bullet",
                title: "No beats yet",
                message: "Edit this rhythm to add a few small actions you'd like to do during this part of the day."
            )
            .rhythmCard()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Beats", subtitle: "Tap to mark complete for today")
                    .padding(.horizontal, 4)
                VStack(spacing: 8) {
                    ForEach(current.sortedBeats) { beat in
                        BeatRow(
                            beat: beat,
                            isCompleted: persistence.isCompleted(beatID: beat.id, on: today),
                            tint: tint,
                            onToggle: { toggle(beat) }
                        )
                        .scaleEffect(pulseBeatID == beat.id ? 1.02 : 1.0)
                        .animation(Theme.springAnimation, value: pulseBeatID)
                    }
                }
            }
        }
    }

    private func toggle(_ beat: Beat) {
        persistence.toggleCompletion(beatID: beat.id, rhythmID: current.id, on: .now)
        triggerPulse(for: beat.id)
#if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
    }

    private func triggerPulse(for id: UUID) {
        pulseBeatID = id
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            if pulseBeatID == id { pulseBeatID = nil }
        }
    }

    // MARK: - Reflection

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Reflection",
                          subtitle: "A short note about how today's rhythm went")
                .padding(.horizontal, 4)

            ZStack(alignment: .topLeading) {
                if reflectionDraft.isEmpty {
                    Text("Optional. A sentence or two is enough.")
                        .font(Typography.body)
                        .foregroundStyle(Theme.tertiaryText)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $reflectionDraft)
                    .focused($reflectionFocused)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 96)
                    .font(Typography.body)
                    .foregroundStyle(Theme.primaryText)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
            )

            if let savedAt = reflectionLastSavedAt {
                Text("Saved at \(savedAt.formatted(.dateTime.hour().minute()))")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.tertiaryText)
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: reflectionLastSavedAt)
    }

    private func loadReflectionIfNeeded() {
        guard !didLoadReflection else { return }
        didLoadReflection = true
        if let existing = persistence.reflection(for: current.id, on: today) {
            reflectionDraft = existing.text
            reflectionLastSavedAt = existing.updatedAt
        }
    }

    private func saveReflection() {
        let trimmed = reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        persistence.saveReflection(
            rhythmID: current.id,
            on: today,
            text: reflectionDraft
        )
        reflectionLastSavedAt = trimmed.isEmpty ? nil : Date()
    }
}

#Preview {
    NavigationStack {
        let r = SampleData.makeSampleDatabase().rhythms[0]
        RhythmDetailView(rhythm: r)
            .environment(PersistenceService.preview)
    }
}
