//
//  CareKitCard.swift
//  OCKSample
//
//  Created by Jai Shah on 28/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum CareKitCard: String, CaseIterable, Identifiable {
	var id: Self { self }
	case button = "Button"
	case checklist = "Checklist"
	case featured = "Featured"
	case grid = "Grid"
	case instruction = "Instruction"
	case labeledValue = "Labeled Value"
	case numericProgress = "Numeric Progress"
	case simple = "Simple"
    case survey = "Survey"
    case custom = "Custom"
    case customEnergy = "Custom Energy"
    case uiKitSurvey = "UIKitSurvey"
}
