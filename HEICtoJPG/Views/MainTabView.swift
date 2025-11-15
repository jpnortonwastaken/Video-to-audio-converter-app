//
//  MainTabView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabItem = .home

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                ConverterView()
                    .tag(TabItem.home)

                ProgressView()
                    .tag(TabItem.progress)

                SettingsView()
                    .tag(TabItem.settings)
            }
            .toolbar(.hidden, for: .tabBar)

            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(OnboardingViewModel())
}
