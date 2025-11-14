//
//  MainTabView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthViewModel
    @State private var selectedTab: TabItem = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(authManager)
                .tag(TabItem.home)

            ProgressView()
                .environmentObject(authManager)
                .tag(TabItem.progress)

            SettingsView()
                .environmentObject(authManager)
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
        .environmentObject(AuthViewModel())
}
