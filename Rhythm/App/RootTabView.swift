//
//  RootTabView.swift
//  Rhythm
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            RhythmsView()
                .tabItem { Label("Rhythms", systemImage: "square.stack") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootTabView()
        .environment(PersistenceService.preview)
        .environment(AICoachService.shared)
}
