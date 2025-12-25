//
//  GradientFadeMask.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct GradientFadeMaskModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: Color.black.opacity(0.1), location: 0.015),
                    .init(color: Color.black.opacity(0.3), location: 0.03),
                    .init(color: Color.black.opacity(0.6), location: 0.045),
                    .init(color: Color.black.opacity(0.85), location: 0.06),
                    .init(color: .black, location: 0.075),
                    .init(color: .black, location: 0.7),
                    .init(color: Color.black.opacity(0.7), location: 0.75),
                    .init(color: Color.black.opacity(0.4), location: 0.8),
                    .init(color: Color.black.opacity(0.1), location: 0.85),
                    .init(color: .clear, location: 0.9),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
        )
    }
}

struct BottomGradientFadeMaskModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black, location: 0.0),
                    .init(color: .black, location: 0.75),
                    .init(color: Color.black.opacity(0.7), location: 0.82),
                    .init(color: Color.black.opacity(0.4), location: 0.88),
                    .init(color: Color.black.opacity(0.1), location: 0.94),
                    .init(color: .clear, location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

extension View {
    func gradientFadeMask() -> some View {
        modifier(GradientFadeMaskModifier())
    }

    func bottomGradientFadeMask() -> some View {
        modifier(BottomGradientFadeMaskModifier())
    }
}
