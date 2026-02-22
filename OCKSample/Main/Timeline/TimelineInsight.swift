//
//  TimelineInsight.swift
//  OCKSample
//
//  Created by Jai Shah on 21/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//


import Foundation

enum TimelineInsight {

    static func message(for normalized: Double) -> String {
        switch normalized {
        case ..<0.25:
            return "Below your typical activity"
        case ..<0.55:
            return "Light activity day"
        case ..<0.8:
            return "Within your normal range"
        default:
            return "Higher activity than usual"
        }
    }
}