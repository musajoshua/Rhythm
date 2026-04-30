//
//  OnboardingView.swift
//  Rhythm
//
//  First-run onboarding: a calm two-page intro followed by a template
//  picker. The user can skip the picker and start blank — Today's empty
//  state will guide them through creating their first rhythm.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(PersistenceService.self) private var persistence
    @State private var viewModel: OnboardingViewModel?
    let onFinish: () -> Void

    var body: some View {
        Group {
            if let vm = viewModel {
                content(viewModel: vm)
            } else {
                Color.clear
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(persistence: persistence)
            }
        }
    }

    @ViewBuilder
    private func content(viewModel vm: OnboardingViewModel) -> some View {
        VStack(spacing: 0) {
            TabView(selection: Binding(
                get: { vm.page },
                set: { vm.page = $0 }
            )) {
                introPage(
                    icon: "sun.horizon",
                    title: "Build your daily rhythm",
                    body: "Rhythm is for routines, not checklists. Group small beats into rhythms like Morning, Midday, Evening, and Night."
                )
                .tag(0)

                introPage(
                    icon: "waveform.path.ecg",
                    title: "Move with momentum",
                    body: "Your rhythm builds quietly over the week. We surface the trend without turning it into a streak you can lose."
                )
                .tag(1)

                templatePage(viewModel: vm)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                PrimaryActionButton(
                    title: vm.page == 2 ? primaryActionTitle(viewModel: vm) : "Continue",
                    systemImage: vm.page == 2 ? "arrow.right" : nil,
                    action: { advance(viewModel: vm) }
                )
                if vm.page == 2 {
                    Button("Start with an empty canvas") {
                        finish(viewModel: vm)
                    }
                    .font(Typography.footnote)
                    .foregroundStyle(Theme.secondaryText)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Pages

    private func introPage(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 120, height: 120)
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Theme.accent)
            }
            VStack(spacing: 12) {
                Text(title)
                    .font(Typography.display)
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.center)
                Text(body)
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func templatePage(viewModel vm: OnboardingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pick a starting point")
                    .font(Typography.display)
                    .foregroundStyle(Theme.primaryText)
                Text("Choose any rhythms you'd like to start with. You can edit or remove them later.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.secondaryText)
            }
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(vm.templates) { template in
                        TemplateRow(
                            template: template,
                            isSelected: vm.isSelected(template),
                            onTap: { vm.toggle(template) }
                        )
                    }
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    // MARK: - Actions

    private func primaryActionTitle(viewModel vm: OnboardingViewModel) -> String {
        vm.hasSelection ? "Add to my rhythm" : "Skip for now"
    }

    private func advance(viewModel vm: OnboardingViewModel) {
        if vm.page < 2 {
            withAnimation { vm.page += 1 }
        } else {
            finish(viewModel: vm)
        }
    }

    private func finish(viewModel vm: OnboardingViewModel) {
        vm.finish()
        onFinish()
    }
}

private struct TemplateRow: View {
    let template: RhythmTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.softTint(for: template.period))
                        .frame(width: 48, height: 48)
                    Image(systemName: template.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.tint(for: template.period))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(Typography.title)
                        .foregroundStyle(Theme.primaryText)
                    Text(template.summary)
                        .font(Typography.footnote)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.divider)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(isSelected ? Theme.accent : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView(onFinish: {})
        .environment(PersistenceService.preview)
}
