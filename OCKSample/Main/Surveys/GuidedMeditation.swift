//
//  GuidedMeditation.swift
//  OCKSample
//
//  Created by Student on 4/29/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import CareKitStore
#if canImport(ResearchKit) && canImport(ResearchKitActiveTask)
import ResearchKit
import ResearchKitActiveTask
#endif

struct GuidedMeditation: Surveyable {
    static var surveyType: Survey {
        Survey.guidedMeditation
    }
}

#if canImport(ResearchKit) && canImport(ResearchKitActiveTask)
extension GuidedMeditation {
    func createSurvey() -> ORKTask {

        let instructionStep = ORKInstructionStep(identifier: "\(identifier()).instruction")
        instructionStep.title = String(localized: "GUIDED_MEDITATION")
        instructionStep.detailText = String(localized: "GUIDED_MEDITATION_INSTRUCTION")

        let meditationStep = ORKActiveStep(identifier: "\(identifier()).meditation")
        meditationStep.title = String(localized: "MEDITATING")
        meditationStep.stepDuration = 60
        meditationStep.shouldShowDefaultTimer = true
        meditationStep.shouldContinueOnFinish = true

        let completionStep = ORKCompletionStep(identifier: "\(identifier()).completion")
        completionStep.title = String(localized: "NAMASTE")
        completionStep.detailText = String(localized: "MEDITATION_COMPLETED")

        let task = ORKOrderedTask(identifier: identifier(), steps: [instructionStep, meditationStep, completionStep])
        return task
    }

    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]? {
        guard result.results != nil else {
            return nil
        }

        var outcome = OCKOutcomeValue(true)
        outcome.kind = "meditationCompleted"

        return [outcome]
    }
}
#endif
