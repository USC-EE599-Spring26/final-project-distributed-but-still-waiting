//
//  SurveyViewSynchronizer.swift
//  OCKSample
//
//  Created by Student on 4/2/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(ResearchKit)

import CareKit
import CareKitStore
import CareKitUI
import ResearchKit
import ResearchKitActiveTask
import UIKit
import os.log


final class SurveyViewSynchronizer: OCKSurveyTaskViewSynchronizer {

    override func updateView(
        _ view: OCKInstructionsTaskView,
        context: OCKSynchronizationContext<OCKTaskEvents>
    ) {
        super.updateView(view, context: context)

        if let event = context.viewModel.first?.first, event.outcome != nil {
            view.instructionsLabel.isHidden = false

            guard let task = event.task as? OCKTask else {
                view.instructionsLabel.text = nil
                return
            }

            switch task.id {
            case Onboard.identifier():
                view.instructionsLabel.text = "Welcome to NeuroMallea. The application is set up and ready to use!"
            case RangeOfMotion.identifier():
                let range = event.answer(kind: #keyPath(ORKRangeOfMotionResult.range))
                view.instructionsLabel.text = "Your Range of Motion Result: \(Int(range))"
            default:
                view.instructionsLabel.isHidden = false
            }

        } else {
            view.instructionsLabel.isHidden = true
        }
    }
}

#endif
