//
//  SettingsView.swift
//  Rhythm
//

import SwiftUI

struct SettingsView: View {
    @Environment(PersistenceService.self) private var persistence
    @State private var viewModel: SettingsViewModel?
    @State private var showingFirstResetConfirm = false
    @State private var showingSecondResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SettingsViewModel(persistence: persistence)
            }
            Task { await viewModel?.refreshAuthStatus() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let vm = viewModel {
            Form {
                paywallSection
                notificationsSection(vm: vm)
                debugSection(vm: vm)
                aboutSection(vm: vm)
                resetSection(vm: vm)
            }
            .scrollContentBackground(.hidden)
        } else {
            Color.clear
        }
    }

    // MARK: - Sections

    private var paywallSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                    Text("Rhythm Pro")
                        .font(Typography.title)
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text("Coming soon")
                        .font(Typography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Theme.accentSoft))
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    bullet("Unlimited rhythms and beats")
                    bullet("On-device AI Coach insights")
                    bullet("Weekly AI reflection summaries")
                    bullet("Richer charts and exports")
                }

                Rectangle()
                    .fill(Theme.divider)
                    .frame(height: 1)
                    .padding(.vertical, 4)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("€2.99 / month")
                            .font(Typography.headline)
                            .foregroundStyle(Theme.primaryText)
                        Text("or €19.99 / year")
                            .font(Typography.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Button("Learn more") {}
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(true)
                }
            }
            .padding(.vertical, 4)
        } footer: {
            Text("Free covers 2 rhythms and 8 beats. Pro is a static preview — payment isn't implemented in this build.")
                .font(Typography.caption)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(Typography.body)
                .foregroundStyle(Theme.primaryText)
        }
    }

    private func notificationsSection(vm: SettingsViewModel) -> some View {
        Section {
            Toggle(isOn: Binding(
                get: { vm.notificationsEnabled },
                set: { newValue in
                    Task { await vm.setNotifications(enabled: newValue) }
                }
            )) {
                Label("Allow notifications", systemImage: "bell")
            }
            if vm.notificationsAuthStatus == .denied {
                Text("Notifications are denied in iOS Settings. Open Settings to allow them.")
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.warning)
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("This is the master permission. Each rhythm sets its own reminder time inside the editor.")
                .font(Typography.caption)
        }
    }

    private func debugSection(vm: SettingsViewModel) -> some View {
        Section("Debug") {
            Button {
                vm.insertSampleData()
            } label: {
                Label("Insert sample week", systemImage: "wand.and.stars")
            }
#if DEBUG
            Button {
                StreakCalculator.runDebugTests()
            } label: {
                Label("Run streak self-tests", systemImage: "checkmark.seal")
            }
#endif
        }
    }

    private func aboutSection(vm: SettingsViewModel) -> some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(vm.versionString)
                    .foregroundStyle(Theme.secondaryText)
            }
            HStack {
                Text("Rhythms")
                Spacer()
                Text("\(vm.rhythmCount)")
                    .foregroundStyle(Theme.secondaryText)
            }
            HStack {
                Text("Beats")
                Spacer()
                Text("\(vm.beatCount)")
                    .foregroundStyle(Theme.secondaryText)
            }
            HStack {
                Text("Completions")
                Spacer()
                Text("\(vm.completionCount)")
                    .foregroundStyle(Theme.secondaryText)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Rhythm")
                    .font(Typography.headline)
                    .foregroundStyle(Theme.primaryText)
                Text("A calmer take on routines: focus on the shape of the day, not the size of the streak.")
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.vertical, 4)
        }
    }

    private func resetSection(vm: SettingsViewModel) -> some View {
        Section {
            Button(role: .destructive) {
                showingFirstResetConfirm = true
            } label: {
                Label("Reset all data", systemImage: "trash")
            }
        }
        .alert("Reset all rhythms and history?", isPresented: $showingFirstResetConfirm) {
            Button("Continue", role: .destructive) {
                showingSecondResetConfirm = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. You'll be asked to confirm one more time.")
        }
        .alert("Are you absolutely sure?", isPresented: $showingSecondResetConfirm) {
            Button("Reset everything", role: .destructive) {
                Task { await viewModel?.resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All rhythms, beats, and completion history will be permanently deleted.")
        }
    }
}

#Preview {
    SettingsView()
        .environment(PersistenceService.preview)
}
