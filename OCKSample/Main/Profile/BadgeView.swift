//
//  BadgeView.swift
//  OCKSample
//
//  Created by Jai Shah on 04/04/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct BadgeView: View {

    let badge: Badge

    var body: some View {
        VStack(spacing: 8) {

            Image(imageName)
                .resizable()
                .frame(width: 80, height: 80)
                .opacity(badge.isUnlocked ? 1.0 : 0.3)

            Text(LocalizedStringKey(badge.titleKey))
                .font(.caption)
                .multilineTextAlignment(.center)
                .opacity(badge.isUnlocked ? 1.0 : 0.5)
        }
        .frame(width: 80)
    }

    private var imageName: String {
        switch badge.category {
        case .streak:
            switch badge.tier {
            case .bronze: return "str_bronze_badge"
            case .silver: return "str_silver_badge"
            case .gold: return "str_gold_badge"
            }
        case .phq:
            switch badge.tier {
            case .bronze: return "phq_bronze_badge"
            case .silver: return "phq_silver_badge"
            case .gold: return "phq_gold_badge"
            }

        default: return ""
        }
    }
}
