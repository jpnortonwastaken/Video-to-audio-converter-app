//
//  CustomTabBar.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

enum TabItem: String, CaseIterable {
    case home
    case progress
    case settings

    var title: String {
        switch self {
        case .home: return "Converter"
        case .progress: return "History"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "arrow.triangle.2.circlepath"
        case .progress: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    HapticManager.shared.tabSelection()
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .white : .gray)

                        Text(tab.title)
                            .font(.caption)
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(TabButtonStyle())
            }
        }
        .frame(height: 50)
        .padding(.horizontal, 40)
        .padding(.top, 12)
        .background(
            Color.black
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// Button style for tab bar - scale only, no background
struct TabButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(
                configuration.isPressed
                    ? .spring(response: 0.3, dampingFraction: 0.65)
                    : .spring(response: 0.4, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}

// Button style for buttons - scale down on press
struct ScaleDownButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(
                configuration.isPressed
                    ? .spring(response: 0.3, dampingFraction: 0.65)
                    : .spring(response: 0.4, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.home))
}
