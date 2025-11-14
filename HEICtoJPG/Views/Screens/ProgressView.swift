//
//  ProgressView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct ProgressView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))

                // Progress Content
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: 100)

                        // Progress Section
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            Text("Progress")
                                .font(.system(size: 32, weight: .bold))
                                .contentTransition(.numericText())

                            Text("Track your progress here")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
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
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ProgressView()
}
