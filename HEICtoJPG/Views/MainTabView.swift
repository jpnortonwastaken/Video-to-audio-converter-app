//
//  MainTabView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabItem = .home

    init() {
        // Hide the default TabView UI completely
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isHidden = true
    }

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
