//
//  HomeView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Home Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(AppConstants.appName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))

                // Home Content
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: 100)

                        // Welcome Section
                        VStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Welcome!")
                                .font(.system(size: 32, weight: .bold))
                                .contentTransition(.numericText())
                        }

                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(24)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .gradientFadeMask()
                .scrollIndicators(.hidden)
                .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            }
            .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            .navigationBarHidden(true)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    HomeView()
}
