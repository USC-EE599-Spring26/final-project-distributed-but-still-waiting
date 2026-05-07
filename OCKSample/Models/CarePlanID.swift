//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Student on 4/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum CarePlanID: String, CaseIterable, Identifiable {
    var id: Self { self }
    case health // Add custom id's for your Care Plans, these are examples
    case wellness
    case nutrition
    case mentalHealth
    case sleepHealth
    case stressReduction
}
