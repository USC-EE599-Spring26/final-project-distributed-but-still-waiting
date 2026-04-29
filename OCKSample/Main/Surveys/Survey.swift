//
//  Survey.swift
//  OCKSample
//
//  Created by Student on 4/1/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore

enum Survey: String, CaseIterable, Identifiable {
    var id: Self { self }
    case onboard = "Onboard"
    case phq9 = "PHQ-9"
    case rangeOfMotion = "Range of Motion"
    case stroop = "Stroop"

    func type() -> Surveyable {
        switch self {
        case .onboard:
            return Onboard()
        case .phq9:
            return PHQ9Survey()
        case .rangeOfMotion:
            return RangeOfMotion()
        case .stroop:
            return Stroop()
        }
    }
}
