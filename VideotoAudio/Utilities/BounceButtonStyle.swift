//
//  BounceButtonStyle.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct BounceButtonStyle: ButtonStyle {
    let scaleAmount: Double

    init(scaleAmount: Double = 0.95) {
        self.scaleAmount = scaleAmount
    }

    func makeBody(configuration: Configuration) -> some View {
        BounceButtonBody(
            configuration: configuration,
            scaleAmount: scaleAmount
        )
    }
}

fileprivate struct BounceButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let scaleAmount: Double

    @State private var isPressedState = false

    var body: some View {
        configuration.label
            .scaleEffect(isPressedState ? scaleAmount : 1.0)
            .onChange(of: configuration.isPressed, initial: false) { oldVal, newVal in
                if newVal {
                    // Bouncy spring press down
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        isPressedState = true
                    }
                } else {
                    // Bouncy spring release
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isPressedState = false
                    }
                }
            }
    }
}
