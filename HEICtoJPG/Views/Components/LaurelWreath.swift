//
//  LaurelWreath.swift
//  HEIC to JPG
//
//  Created by Claude on 11/23/25.
//

import SwiftUI

struct LaurelWreath: View {
    enum Side {
        case left
        case right
    }

    let side: Side
    let color: Color

    var body: some View {
        ZStack {
            // Create a laurel branch with multiple leaves
            VStack(spacing: -8) {
                // Top leaves
                LeafPair(rotation: side == .left ? -20 : 20)
                LeafPair(rotation: side == .left ? -10 : 10)
                LeafPair(rotation: 0)
                LeafPair(rotation: side == .left ? 10 : -10)
                LeafPair(rotation: side == .left ? 20 : -20)
            }
            .scaleEffect(x: side == .left ? -1 : 1)
        }
        .foregroundColor(color)
    }
}

struct LeafPair: View {
    let rotation: Double

    var body: some View {
        HStack(spacing: 2) {
            // Left leaf
            Leaf()
                .rotationEffect(.degrees(-30 + rotation))

            // Right leaf
            Leaf()
                .rotationEffect(.degrees(30 + rotation))
        }
        .frame(height: 8)
    }
}

struct Leaf: View {
    var body: some View {
        Ellipse()
            .fill(Color.yellow.opacity(0.9))
            .frame(width: 6, height: 12)
            .shadow(color: .yellow.opacity(0.3), radius: 1, x: 0, y: 0)
    }
}

#Preview {
    HStack(spacing: 20) {
        LaurelWreath(side: .left, color: .yellow)

        HStack(spacing: 4) {
            ForEach(0..<5) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
            }
        }

        LaurelWreath(side: .right, color: .yellow)
    }
    .padding()
    .background(Color.black)
}
