//
//  SurveyViewSynchronizer.swift
//  OCKSample
//
//  Created by Student on 4/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(ResearchKit) && canImport(ResearchKitUI)

import CareKit
import CareKitStore
import CareKitUI
import Foundation
import ResearchKit
import UIKit
#if canImport(ResearchKitActiveTask)
import ResearchKitActiveTask
#endif

final class SurveyViewSynchronizer: OCKSurveyTaskViewSynchronizer {

    override func updateView(
        _ view: OCKInstructionsTaskView,
        context: OCKSynchronizationContext<OCKTaskEvents>
    ) {
        super.updateView(view, context: context)

        let event = context.viewModel.first?.first

        var instructionsText: String?
        if let event, let task = event.task as? OCKTask {
            instructionsText = task.instructions

            switch task.id {
            case Onboard.identifier():
                if event.outcome != nil {
                    instructionsText = String(localized: "SURVEY_ONBOARD_COMPLETE_MESSAGE")
                }
            case PHQ9Survey.identifier():
                if event.outcome != nil {
                    let score = phq9Score(from: event) ?? 0
                    let severity = PHQ9Severity(score: score).localizedTitle
                    instructionsText = String(
                        format: String(localized: "PHQ9_RESULTS_SUMMARY_FORMAT"),
                        score,
                        severity
                    )
                }
            #if canImport(ResearchKitActiveTask)
            case Stroop.identifier():
                if event.outcome != nil {
                    let correct = Int(event.answer(kind: "correct"))
                    let incorrect = Int(event.answer(kind: "incorrect"))
                    let reactionTime = event.answer(kind: "reactionTime")
                    let formattedReactionTime = String(format: "%.2f", reactionTime)
                    instructionsText = String(
                        format: String(localized: "STROOP_RESULTS_SUMMARY_FORMAT"),
                        correct,
                        incorrect,
                        formattedReactionTime
                    )
                }
            case RangeOfMotion.identifier():
                if event.outcome != nil {
                    let range = event.answer(kind: #keyPath(ORKRangeOfMotionResult.range))
                    instructionsText = String(
                        format: String(localized: "RANGE_OF_MOTION_RESULT_FORMAT"),
                        Int(range)
                    )
                }
            #endif
            default:
                break
            }
        }

        let shouldShowInstructions = !(instructionsText?.isEmpty ?? true)

        MainActor.assumeIsolated {
            view.instructionsLabel.isHidden = !shouldShowInstructions
            view.instructionsLabel.text = instructionsText
            view.instructionsLabel.font = .preferredFont(forTextStyle: .footnote)
            view.instructionsLabel.textColor = .secondaryLabel
        }
    }
}

#endif
