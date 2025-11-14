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
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(TabItem.home)

            ProgressView()
                .tag(TabItem.progress)

            SettingsView()
                .tag(TabItem.settings)
        }
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .bottom) {
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(OnboardingViewModel())
}
