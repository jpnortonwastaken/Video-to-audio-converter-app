//
//  Font+Rounded.swift
//  HEIC to JPG
//
//  Created by Claude on 11/18/25.
//

import SwiftUI

extension Font {
    // MARK: - Rounded Font Variants

    static func roundedLargeTitle() -> Font {
        .system(.largeTitle, design: .rounded)
    }

    static func roundedTitle() -> Font {
        .system(.title, design: .rounded)
    }

    static func roundedTitle2() -> Font {
        .system(.title2, design: .rounded)
    }

    static func roundedTitle3() -> Font {
        .system(.title3, design: .rounded)
    }

    static func roundedHeadline() -> Font {
        .system(.headline, design: .rounded)
    }

    static func roundedSubheadline() -> Font {
        .system(.subheadline, design: .rounded)
    }

    static func roundedBody() -> Font {
        .system(.body, design: .rounded)
    }

    static func roundedCallout() -> Font {
        .system(.callout, design: .rounded)
    }

    static func roundedCaption() -> Font {
        .system(.caption, design: .rounded)
    }

    static func roundedCaption2() -> Font {
        .system(.caption2, design: .rounded)
    }

    static func roundedFootnote() -> Font {
        .system(.footnote, design: .rounded)
    }

    // MARK: - Rounded Font with Size

    static func roundedSystem(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
