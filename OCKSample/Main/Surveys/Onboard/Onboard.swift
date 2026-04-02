//
//  Onboard.swift
//  OCKSample
//
//  Created by Student on 4/1/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import HealthKit
#if canImport(ResearchKit)
import ResearchKit
#endif

struct Onboard: Surveyable {
    static var surveyType: Survey {
        Survey.onboard
    }
}

#if canImport(ResearchKit)
extension Onboard {
    func createSurvey() -> ORKTask {
        // The Welcome Instruction step.
        let welcomeInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).welcome"
        )

        welcomeInstructionStep.title = "Welcome to NeuroMallea!"
        welcomeInstructionStep.detailText = """
        Your companion app to improving your mental health through personalized care plans.
        """
        welcomeInstructionStep.image = UIImage(named: "NeuroMalleaBackground")
        welcomeInstructionStep.imageContentMode = .scaleToFill

        // The Informed Consent Instruction step.
        let studyOverviewInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).overview"
        )

        studyOverviewInstructionStep.title = "Improve your mental health by:"
        studyOverviewInstructionStep.iconImage = UIImage(systemName: "waveform.path.ecg")

        let trackBodyItem = ORKBodyItem(
            text: "Keeping track of your health data, particularly mental health and sleep.",
            detailText: nil,
            image: UIImage(systemName: "heart.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let completeTasksBodyItem = ORKBodyItem(
            text: "Completing assigned CBT exercises and surveys to monitor your progress.",
            detailText: nil,
            image: UIImage(systemName: "bell.circle.fill"),
            learnMoreItem: ORKLearnMoreItem(
                text: "Learn how CBT works",
                learnMoreInstructionStep: {
                    let step = ORKLearnMoreInstructionStep(identifier: "cbt.learnmore")
                    step.title = "What is CBT?"
                    step.text = """
                    Cognitive Behavioral Therapy (CBT) helps you recognize and change negative thought patterns.
                    """
                    step.image = UIImage(systemName: "brain.head.profile")
                    step.imageContentMode = .scaleAspectFit
                    return step
                }()
            ),
            bodyItemStyle: .image
        )

        let remindersBodyItem = ORKBodyItem(
            text: "Reminders for CBT-related tasks, such as journaling, meditation, and taking prescribed medication.",
            detailText: nil,
            image: UIImage(systemName: "bell.circle.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let signatureBodyItem = ORKBodyItem(
            text: "Before joining, we will ask you to sign an informed consent document.",
            detailText: "This document will allow us to utilize your data to improve mental health services.",
            image: UIImage(systemName: "signature"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let secureDataBodyItem = ORKBodyItem(
            text: "Your data is kept private and secure.",
            detailText: """
            We will only use your information to tailor your care plan and will not share your data with third parties.
            """,
            image: UIImage(systemName: "lock.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        studyOverviewInstructionStep.bodyItems = [
            trackBodyItem,
            completeTasksBodyItem,
            remindersBodyItem,
            signatureBodyItem,
            secureDataBodyItem
        ]

        // The Signature step.
        let termsOfServiceStep = ORKWebViewStep(
            identifier: "\(identifier()).consent",
            html: informedConsentHTML
        )

        termsOfServiceStep.showSignatureAfterContent = true

        let healthKitTypesToWrite: Set<HKSampleType> = [
            .categoryType(forIdentifier: .sleepAnalysis)!
        ]

        let healthKitTypesToRead: Set<HKObjectType> = [
            .categoryType(forIdentifier: .sleepAnalysis)!,
            .quantityType(forIdentifier: .heartRate)!
        ]

        let healthKitPermissionType = ORKHealthKitPermissionType(
            sampleTypesToWrite: healthKitTypesToWrite,
            objectTypesToRead: healthKitTypesToRead
        )

        let notificationsPermissionType = ORKNotificationPermissionType(
            authorizationOptions: [.alert, .badge, .sound]
        )

        let motionPermissionType = ORKMotionActivityPermissionType()

        let requestPermissionsStep = ORKRequestPermissionsStep(
            identifier: "\(identifier()).requestPermissionsStep",
            permissionTypes: [
                healthKitPermissionType,
                notificationsPermissionType,
                motionPermissionType
            ]
        )

        requestPermissionsStep.title = "Sleep and Health Data Permission"
        // swiftlint:disable:next line_length
        requestPermissionsStep.text = "Review the following sleep and health data below and provide permissions to allow us to tailor your care to your health."

        // Completion Step
        let completionStep = ORKCompletionStep(
            identifier: "\(identifier()).completionStep"
        )

        completionStep.title = "NeuroMallea is now live!"
        // swiftlint:disable:next line_length
        completionStep.text = "Begin working towards your health and well-being with the NeuroMallea app. We look forward to supporting you on this journey!"

        let surveyTask = ORKOrderedTask(
            identifier: identifier(),
            steps: [
                welcomeInstructionStep,
                studyOverviewInstructionStep,
                termsOfServiceStep,
                requestPermissionsStep,
                completionStep
            ]
        )
        return surveyTask
    }

    func extractAnswers(_ result: ORKTaskResult) -> [CareKitStore.OCKOutcomeValue]? {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Utility.requestHealthKitPermissions()
        }
        return [OCKOutcomeValue(Date())]
    }
}
#endif
