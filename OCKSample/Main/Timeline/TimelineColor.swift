//
//  TimelineColor.swift
//  OCKSample
//
//  Created by Jai Shah on 21/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
enum TimelineColor {
    static func color(for normalizedValue: Double) -> Color {
        // Clamp just to be safe
        let v = max(0, min(1, normalizedValue))

        // Blue → Red interpolation
        return Color(
            red: v,
            green: 0.2,
            blue: 1.0 - v
        )
    }
}
