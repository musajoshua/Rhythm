//
//  RhythmEditorView.swift
//  Rhythm
//

import SwiftUI

struct RhythmEditorView: View {
    let existingRhythm: Rhythm?
    /// Called after a successful save or delete so callers can refresh.
    var onChange: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(PersistenceService.self) private var persistence
    @State private var viewModel: RhythmEditorViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if let vm = viewModel {
                    EditorForm(viewModel: vm, onChange: onChange, dismiss: dismiss)
                } else {
                    Color.clear
                }
            }
            .navigationTitle(viewModel?.isEditing == true ? "Edit Rhythm" : "New Rhythm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel?.save()
                        onChange()
                        dismiss()
                    }
                    .disabled(!(viewModel?.canSave ?? false))
                    .font(.body.weight(.semibold))
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RhythmEditorViewModel(existing: existingRhythm, persistence: persistence)
            }
        }
    }
}

/// The actual form. Pulled out so we can use `@Bindable` against the VM.
private struct EditorForm: View {
    @Bindable var viewModel: RhythmEditorViewModel
    let onChange: () -> Void
    let dismiss: DismissAction
    @State private var showDeleteConfirmation = false
    @State private var editMode: EditMode = .inactive

    fileprivate static let iconChoices: [String] = [
        "sunrise", "sun.max", "sun.haze", "moon.stars",
        "leaf", "book.closed", "figure.run", "heart",
        "cup.and.saucer", "sparkles", "wind", "bed.double",
        "figure.flexibility", "brain.head.profile", "music.note",
        "fork.knife", "drop", "timer", "calendar"
    ]

    fileprivate static let beatSymbols: [String] = [
        "circle", "figure.flexibility", "figure.mind.and.body", "brain.head.profile",
        "book", "book.closed", "cup.and.saucer", "leaf", "sun.max", "moon.stars",
        "drop", "fork.knife", "figure.walk", "figure.run", "dumbbell", "pencil",
        "calendar", "timer", "music.note", "headphones", "bed.double",
        "heart", "lungs", "pawprint", "sparkles"
    ]

    var body: some View {
        Form {
            rhythmSection
            periodSection
            iconSection
            reminderSection
            beatsSection
            if viewModel.isEditing { deleteSection }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .environment(\.editMode, $editMode)
        .confirmationDialog(
            "Delete this rhythm? Its history will be removed.",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.delete()
                onChange()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Sections

    private var rhythmSection: some View {
        Section("Rhythm") {
            TextField(
                "Rhythm name",
                text: Binding(
                    get: { viewModel.name },
                    set: { viewModel.name = String($0.prefix(40)) }
                ),
                prompt: Text("e.g. Morning Reset")
            )
            .textInputAutocapitalization(.words)

            TextField(
                "Notes",
                text: $viewModel.notes,
                prompt: Text("Optional"),
                axis: .vertical
            )
            .lineLimit(2...4)
        }
    }

    private var periodSection: some View {
        Section("Time of day") {
            Picker("Period", selection: Binding(
                get: { viewModel.period },
                set: { viewModel.period = $0; viewModel.didChangePeriod() }
            )) {
                ForEach(RhythmPeriod.allCases) { p in
                    Text(p.displayName).tag(p)
                }
            }
            Text(viewModel.period.tagline)
                .font(Typography.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Self.iconChoices, id: \.self) { name in
                        Button {
                            viewModel.pickIcon(name)
                        } label: {
                            Image(systemName: name)
                                .font(.system(size: 20, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .foregroundStyle(viewModel.iconName == name
                                                 ? Theme.tint(for: viewModel.period)
                                                 : Theme.secondaryText)
                                .background(
                                    Circle().fill(viewModel.iconName == name
                                                  ? Theme.softTint(for: viewModel.period)
                                                  : Theme.surfaceMuted)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Daily reminder", isOn: Binding(
                get: { viewModel.hasReminder },
                set: { newValue in
                    viewModel.hasReminder = newValue
                    if newValue {
                        // First-time enable: ask iOS for permission so the
                        // reminder can actually fire. No-ops if already
                        // decided.
                        Task { await NotificationService.shared.requestAuthorizationIfNeeded() }
                    }
                }
            ))
            if viewModel.hasReminder {
                DatePicker(
                    "Time",
                    selection: $viewModel.reminderTime,
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Reminder")
        } footer: {
            Text("Reminders fire on every active day at the time you pick. You may be prompted to allow notifications.")
                .font(Typography.caption)
        }
    }

    private var beatsSection: some View {
        Section {
            ForEach($viewModel.beats, id: \.id) { $draft in
                BeatDraftRow(draft: $draft,
                             periodTint: Theme.tint(for: viewModel.period),
                             symbols: Self.beatSymbols)
            }
            .onDelete { offsets in viewModel.removeBeat(at: offsets) }
            .onMove { src, dst in viewModel.moveBeat(from: src, to: dst) }

            Button {
                viewModel.addBeat()
            } label: {
                Label("Add beat", systemImage: "plus.circle")
                    .foregroundStyle(Theme.tint(for: viewModel.period))
            }
        } header: {
            HStack {
                Text("Beats")
                Spacer()
                if !viewModel.beats.isEmpty {
                    EditButton().font(Typography.footnote)
                }
            }
        } footer: {
            Text("Required beats count toward rhythm completion. Optional ones are nice-to-haves.")
                .font(Typography.caption)
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete rhythm", systemImage: "trash")
            }
        }
    }
}

private struct BeatDraftRow: View {
    @Binding var draft: RhythmEditorViewModel.BeatDraft
    let periodTint: Color
    let symbols: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Menu {
                    ForEach(symbols, id: \.self) { sym in
                        Button {
                            draft.symbolName = sym
                        } label: {
                            Label(sym, systemImage: sym)
                        }
                    }
                } label: {
                    Image(systemName: draft.symbolName)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(periodTint.opacity(0.15)))
                        .foregroundStyle(periodTint)
                }

                TextField("Beat name", text: $draft.name)

                Toggle(isOn: $draft.isRequired) {
                    Text(draft.isRequired ? "Required" : "Optional")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                .toggleStyle(.button)
                .tint(periodTint)
                .controlSize(.small)
            }

            TextField(
                "Details",
                text: $draft.details,
                prompt: Text("Optional"),
                axis: .vertical
            )
            .font(Typography.footnote)
            .foregroundStyle(Theme.secondaryText)
            .lineLimit(1...3)

            HStack(spacing: 8) {
                Text("Duration")
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                TextField(
                    "Optional",
                    value: $draft.durationMinutes,
                    format: .number
                )
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .frame(maxWidth: 80)
                Text("min")
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.tertiaryText)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview("New") {
    RhythmEditorView(existingRhythm: nil)
        .environment(PersistenceService.preview)
}

#Preview("Edit") {
    RhythmEditorView(existingRhythm: SampleData.makeSampleDatabase().rhythms[0])
        .environment(PersistenceService.preview)
}
