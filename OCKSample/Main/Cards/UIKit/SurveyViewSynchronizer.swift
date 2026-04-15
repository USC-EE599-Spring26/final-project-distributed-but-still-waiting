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
import ResearchKit
import UIKit
import os.log
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
        let shouldShowInstructions = event?.outcome != nil

        var instructionsText: String?
        if let event, let task = event.task as? OCKTask {
            switch task.id {
            case Onboard.identifier():
                instructionsText = "Welcome to NeuroMallea. The application is set up and ready to use!"
            #if canImport(ResearchKitActiveTask)
            case RangeOfMotion.identifier():
                let range = event.answer(kind: #keyPath(ORKRangeOfMotionResult.range))
                instructionsText = "Your Range of Motion Result: \(Int(range))"
            #endif
            default:
                instructionsText = nil
            }
        }

        MainActor.assumeIsolated {
            view.instructionsLabel.isHidden = !shouldShowInstructions
            view.instructionsLabel.text = instructionsText
        }
    }
}

#endif
