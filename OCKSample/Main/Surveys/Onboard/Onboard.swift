//
//  Onboard.swift
//  OCKSample
//
//  Created by Jai Shah on 31/03/26.
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
	/*
	 TOD: Modify the onboarding so it properly represents the
	 usecase of your application. Changes should be made to
	 each of the steps in this type method. For example, you
	 should change: title, detailText, image, and imageContentMode,
	 and learnMoreItem.
	 */
    func createSurvey() -> ORKTask {

        // MARK: - Welcome Step
        let welcomeInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).welcome"
        )

        welcomeInstructionStep.title = "Welcome to NeuroMallea"
        welcomeInstructionStep.detailText = """
        Build healthier thought patterns using guided CBT exercises, mood tracking, and
reflections. Tap Next to get started.
"""
        welcomeInstructionStep.image = UIImage(systemName: "brain.head.profile")
        welcomeInstructionStep.imageContentMode = .scaleAspectFit

        // MARK: - Overview Step
        let overviewStep = ORKInstructionStep(
            identifier: "\(identifier()).overview"
        )

        overviewStep.title = "How NeuroMallea Helps You"
        overviewStep.iconImage = UIImage(systemName: "sparkles")

        let trackThoughtsItem = ORKBodyItem(
            text: "Track thoughts and emotions",
            detailText: "Log negative thoughts, triggers, and mood patterns to increase self-awareness.",
            image: UIImage(systemName: "pencil.and.outline"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let cbtExercisesItem = ORKBodyItem(
            text: "Practice CBT techniques",
            detailText: "Reframe negative thinking, practice breathing exercises, and build resilience.",
            image: UIImage(systemName: "brain"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let remindersItem = ORKBodyItem(
            text: "Stay consistent with reminders",
            detailText: "Receive gentle nudges to complete exercises and maintain your mental wellness routine.",
            image: UIImage(systemName: "bell.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        let privacyItem = ORKBodyItem(
            text: "Your data stays private",
            detailText: "Your entries are securely stored and never shared without your consent.",
            image: UIImage(systemName: "lock.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )

        overviewStep.bodyItems = [
            trackThoughtsItem,
            cbtExercisesItem,
            remindersItem,
            privacyItem
        ]

        // MARK: - Consent Step
        let consentStep = ORKWebViewStep(
            identifier: "\(identifier()).consent",
            html: informedConsentHTML
        )
        consentStep.showSignatureAfterContent = true

        // MARK: - Permissions Step

        let healthKitTypesToWrite: Set<HKSampleType> = []

        let healthKitTypesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        let healthKitPermissionType = ORKHealthKitPermissionType(
            sampleTypesToWrite: healthKitTypesToWrite,
            objectTypesToRead: healthKitTypesToRead
        )

        let notificationsPermissionType = ORKNotificationPermissionType(
            authorizationOptions: [.alert, .sound, .badge]
        )

        let requestPermissionsStep = ORKRequestPermissionsStep(
            identifier: "\(identifier()).permissions",
            permissionTypes: [
                healthKitPermissionType,
                notificationsPermissionType
            ]
        )

        requestPermissionsStep.title = "Stay on Track"
        requestPermissionsStep.text = """
        Enable notifications for reminders and optionally share health data like sleep or heart
 rate to improve your insights.
"""

        // MARK: - Completion Step
        let completionStep = ORKCompletionStep(
            identifier: "\(identifier()).completion"
        )

        completionStep.title = "You're All Set 🎉"
        completionStep.text = """
Start your journey toward better mental well-being with NeuroMallea. Small steps every day make a big
 difference.
"""

        // MARK: - Task
        let surveyTask = ORKOrderedTask(
            identifier: identifier(),
            steps: [
                welcomeInstructionStep,
                overviewStep,
                consentStep,
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
