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
    static let lexapro = "lexapro"
    static let cbtExercises = "cbtExercises"
    static let sleepResult = "sleepResult"
    static let phq9Survey = "phq9Survey"
    static let depression = "depression"
    static let qualityOfLife = "qualityOfLife"
    static let phq9 = "phq9"
    static let energy = "energy"
    static let bedtimeChecklist = "bedtimeChecklist"
    static let stroop = "stroop-task"
    static let heartRate = "heartRate"

    static var ordered: [String] {
        orderedObjective + orderedSubjective
    }

    static var orderedObjective: [String] {
        [ Self.steps, Self.sleepResult, Self.heartRate]
    }

    static var orderedSubjective: [String] {
        [ Self.doxylamine, Self.kegels, Self.energy, Self.nausea, Self.phq9Survey, Self.cbtExercises, Self.lexapro,
          Self.depression, Self.bedtimeChecklist]
    }

    static var orderedWatchOS: [String] {
        [ Self.doxylamine, Self.kegels, Self.energy, Self.phq9Survey, Self.cbtExercises, Self.lexapro,
          Self.depression, Self.bedtimeChecklist]
    }
}
