//
//  TaskID.swift
//  OCKSample
//
//  Created by Corey Baker on 4/14/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum TaskID {
    static let doxylamine = "doxylamine"
    static let nausea = "nausea"
    static let stretch = "stretch"
    static let kegels = "kegels"
    static let steps = "steps"
    static let ovulationTestResult = "ovulationTestResult"
    static let lexapro = "lexapro"
    static let cbtExercises = "cbtExercises"
    static let sleepDuration = "Sleep Duration"
    static let ph9Survey = "ph9Survey"
    static let depression = "depression"
    static let qualityOfLife = "qualityOfLife"

    static var ordered: [String] {
        orderedObjective + orderedSubjective
    }

    static var orderedObjective: [String] {
        [ Self.steps, Self.ovulationTestResult, Self.sleepDuration]
    }

    static var orderedSubjective: [String] {
        [ Self.doxylamine, Self.kegels, Self.stretch, Self.nausea, Self.ph9Survey, Self.cbtExercises, Self.lexapro,
          Self.depression]
    }

    static var orderedWatchOS: [String] {
        [ Self.doxylamine, Self.kegels, Self.stretch, Self.ph9Survey, Self.cbtExercises, Self.lexapro, Self.depression]
    }
}
