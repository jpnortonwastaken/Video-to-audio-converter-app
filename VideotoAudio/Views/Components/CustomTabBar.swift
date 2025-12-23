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
        case .progress: return "list.bullet.below.rectangle"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    HapticManager.shared.tabSelection()
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.roundedSystem(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab ? (colorScheme == .light ? .black : .white) : .gray)

                        Text(tab.title)
                            .font(.roundedCaption())
                            .foregroundColor(selectedTab == tab ? (colorScheme == .light ? .black : .white) : .gray)
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
            (colorScheme == .light ? Color.white : Color(.systemGray6))
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill((colorScheme == .light ? Color.black.opacity(0.1) : Color.white.opacity(0.1)))
                        .frame(height: 1)
                }
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

// Button style for buttons - scale down on press with bouncy spring
struct ScaleDownButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(
                configuration.isPressed
                    ? .spring(response: 0.3, dampingFraction: 0.5)
                    : .spring(response: 0.45, dampingFraction: 0.45),
                value: configuration.isPressed
            )
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.home))
}
