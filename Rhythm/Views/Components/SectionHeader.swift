//
//  SectionHeader.swift
//  Rhythm
//

import SwiftUI

/// Lightweight section header used between cards on the home screen and
/// inside detail views. Title is rounded medium-weight; an optional
/// subtitle drops below in tertiary text.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    init(_ title: String, subtitle: String? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(Theme.primaryText)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Typography.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            Spacer()
            if let trailing { trailing }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SectionHeader("Today", subtitle: "Your rhythm for the day")
        .padding()
        .background(Theme.background)
}
