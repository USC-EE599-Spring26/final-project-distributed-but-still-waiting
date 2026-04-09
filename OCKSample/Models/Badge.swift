//
//  Badge.swift
//  OCKSample
//
//  Created by Jai Shah on 04/04/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum BadgeTier: String {
    case bronze
    case silver
    case gold
}
enum BadgeCategory {
    case streak
    case phq
    case run
}

struct Badge: Identifiable {
    let id: String
    let titleKey: String
    let descriptionKey: String
    let tier: BadgeTier
    let category: BadgeCategory
    let isUnlocked: Bool
}
