//
//  OCKStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitEssentials
import CareKitStore
import Contacts
import os.log
import ParseSwift
import ParseCareKit
import ResearchKitSwiftUI

extension OCKStore {

    @MainActor
        class func getCarePlanUUIDs() async throws -> [CarePlanID: UUID] {
            var results = [CarePlanID: UUID]()

            guard let store = AppDelegateKey.defaultValue?.store else {
                return results
            }

            var query = OCKCarePlanQuery(for: Date())
            query.ids = CarePlanID.allCases.map { $0.rawValue }

            let foundCarePlans = try await store.fetchCarePlans(query: query)
            // Populate the dictionary for all CarePlan's
            CarePlanID.allCases.forEach { carePlanID in
                results[carePlanID] = foundCarePlans
                    .first(where: { $0.id == carePlanID.rawValue })?.uuid
            }
            return results
        }

        // TOD: Rewrite this method in a functional programming way.
        /**
         Adds an `OCKAnyCarePlan`*asynchronously*  to `OCKStore` if it has not been added already.

         - parameter carePlans: The array of `OCKAnyCarePlan`'s to be added to the `OCKStore`.
         - parameter patientUUID: The uuid of the `OCKPatient` to tie to the `OCKCarePlan`. Defaults to nil.
         - throws: An error if there was a problem adding the missing `OCKAnyCarePlan`'s.
         - note: `OCKAnyCarePlan`'s that have an existing `id` will not be added and will not cause errors to be thrown.
        */
        func addCarePlansIfNotPresent(
            _ carePlans: [OCKAnyCarePlan],
            patientUUID: UUID? = nil
        ) async throws {
            let carePlanIdsToAdd = carePlans.compactMap { $0.id }

            // Prepare query to see if Care Plan are already added
            var query = OCKCarePlanQuery(for: Date())
            query.ids = carePlanIdsToAdd
            let foundCarePlans = try await self.fetchAnyCarePlans(query: query)
//            var carePlanNotInStore = [OCKAnyCarePlan]()
//            // Check results to see if there's a missing Care Plan
//            carePlans.forEach { potentialCarePlan in
//                if foundCarePlans.first(where: { $0.id == potentialCarePlan.id }) == nil {
//                    // Check if can be casted to OCKCarePlan to add patientUUID
//                    guard var mutableCarePlan = potentialCarePlan as? OCKCarePlan else {
//                        carePlanNotInStore.append(potentialCarePlan)
//                        return
//                    }
//                    mutableCarePlan.patientUUID = patientUUID
//                    carePlanNotInStore.append(mutableCarePlan)
//                }
//            }

            // Functional version
            let existingIds = Set(foundCarePlans.compactMap { $0.id })

            let carePlanNotInStore: [OCKAnyCarePlan] = carePlans
                .filter { potentialCarePlan in
                    return !existingIds.contains(potentialCarePlan.id)
                }
                .map { potentialCarePlan in

                    guard var mutableCarePlan = potentialCarePlan as? OCKCarePlan else {
                        return potentialCarePlan
                    }
                    mutableCarePlan.patientUUID = patientUUID
                    return mutableCarePlan
                }

            // Only add if there's a new Care Plan
            if carePlanNotInStore.count > 0 {
                do {
                    _ = try await self.addAnyCarePlans(carePlanNotInStore)
                    Logger.ockStore.info("Added Care Plans into OCKStore!")
                } catch {
                    Logger.ockStore.error("Error adding Care Plans: \(error.localizedDescription)")
                }
            }
        }

        // TOD: Rewrite this method in a functional programming way.

    func addContactsIfNotPresent(_ contacts: [OCKContact]) async throws -> [OCKContact] {
        let contactIdsToAdd = contacts.compactMap { $0.id }

        // Prepare query to see if contacts are already added
        var query = OCKContactQuery(for: Date())
        query.ids = contactIdsToAdd

        let foundContacts = try await fetchContacts(query: query)

        // Find all missing tasks.
//        let contactsNotInStore = contacts.filter { potentialContact -> Bool in
//            guard foundContacts.first(where: { $0.id == potentialContact.id }) == nil else {
//                return false
//            }
//            return true
//        }
        // Functional version -
        let existingIds = Set(foundContacts.map { $0.id })

        let contactsNotInStore = contacts.filter { potentialContact in
            return !existingIds.contains(potentialContact.id)
        }
        // Only add if there's a new task
        guard contactsNotInStore.count > 0 else {
            return []
        }

        let addedContacts = try await addContacts(contactsNotInStore)
        return addedContacts
    }

    func populateCarePlans(patientUUID: UUID? = nil) async throws {
        // TOD: Add at least 2 more CarePlans.
        let mentalHealthCarePlan = OCKCarePlan(
            id: CarePlanID.mentalHealth.rawValue,
            title: "Mental Health Care Plan",
            patientUUID: patientUUID
        )

        let mentalWellnessCarePlan = OCKCarePlan(
                id: CarePlanID.mentalWellness.rawValue,
                title: "Mental Wellness",
                patientUUID: patientUUID
            )
        let stressManagementCarePlan = OCKCarePlan(
            id: CarePlanID.stressManagement.rawValue,
            title: "Stress Management",
            patientUUID: patientUUID
        )

        // CHANGE: Pass all care plans together
        try await addCarePlansIfNotPresent(
            [
                mentalHealthCarePlan,
                mentalWellnessCarePlan,
                stressManagementCarePlan
            ],
            patientUUID: patientUUID
        )
    }

    // Adds tasks and contacts into the store
    func populateDefaultCarePlansTasksContacts(
        _ patientUUID: UUID? = nil,
        startDate: Date = Date()
	) async throws {
        try await populateCarePlans(patientUUID: patientUUID)

        // TOD: Relate all tasks to a respective CarePlan
        let carePlanUUIDs = try await Self.getCarePlanUUIDs()

        let thisMorning = Calendar.current.startOfDay(for: startDate)
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let afterLunch = Calendar.current.date(byAdding: .hour, value: 14, to: aFewDaysAgo)!

        let schedule = OCKSchedule(
            composing: [
                OCKScheduleElement(
                    start: beforeBreakfast,
                    end: nil,
                    interval: DateComponents(day: 1)
                ),
                OCKScheduleElement(
                    start: afterLunch,
                    end: nil,
                    interval: DateComponents(day: 2)
                )
            ]
        )

        var lexapro = OCKTask(
            id: TaskID.lexapro,
            title: String(localized: "TAKE_LEXAPRO"),
            carePlanUUID: carePlanUUIDs[.mentalHealth],
            schedule: schedule
        )
        lexapro.instructions = String(localized: "LEXAPRO_INSTRUCTIONS")
        lexapro.asset = "pills.fill"
        lexapro.priority = 1
        lexapro.card = .custom

        let cbtExerciseElement = OCKScheduleElement(
            start: beforeBreakfast,
            end: nil,
            interval: DateComponents(hour: 3)
        )
        let cbtExerciseSchedule = OCKSchedule(
            composing: [cbtExerciseElement]
        )
        var cbtExercises = OCKTask(
            id: TaskID.cbtExercises,
            title: String(localized: "CBT_EXERCISES"),
            carePlanUUID: carePlanUUIDs[.mentalHealth],
            schedule: cbtExerciseSchedule
        )
        cbtExercises.impactsAdherence = true
        cbtExercises.instructions = String(localized: "CBT_INSTRUCTIONS")
        cbtExercises.priority = 2
        cbtExercises.card = .button

        let depressionSchedule = OCKSchedule(
            composing: [
                OCKScheduleElement(
                    start: beforeBreakfast,
                    end: nil,
                    interval: DateComponents(day: 1),
                    text: String(localized: "ANYTIME_DURING_DAY"),
                    targetValues: [],
                    duration: .allDay
                )
            ]
        )

        var depression = OCKTask(
            id: TaskID.depression,
            title: String(localized: "TRACK_DEPRESSION"),
            carePlanUUID: carePlanUUIDs[.mentalHealth],
            schedule: depressionSchedule
        )
        depression.impactsAdherence = false
        depression.instructions = String(localized: "DEPRESSION_INSTRUCTIONS")
        depression.asset = "bed.double"
        depression.priority = 3
        depression.card = .simple

        let stretchElement = OCKScheduleElement(
            start: beforeBreakfast,
            end: nil,
            interval: DateComponents(day: 1)
        )
        let stretchSchedule = OCKSchedule(
            composing: [stretchElement]
        )
        var stretch = OCKTask(
            id: TaskID.stretch,
            title: String(localized: "STRETCH"),
            carePlanUUID: carePlanUUIDs[.mentalHealth],
            schedule: stretchSchedule
        )
        stretch.impactsAdherence = true
        stretch.asset = "figure.walk"
        stretch.priority = 4

        let qualityOfLife = createQualityOfLifeSurveyTask(carePlanUUID: carePlanUUIDs[.mentalHealth])

        _ = try await addTasksIfNotPresent(
            [
                depression,
                lexapro,
                cbtExercises,
                stretch,
                qualityOfLife
            ]
        )
        _ = try await addOnboardingTask(carePlanUUIDs[.mentalHealth])
        _ = try await addUIKitSurveyTasks(carePlanUUIDs[.mentalHealth])

        var contact1 = OCKContact(
            id: "jane",
            givenName: "Jane",
            familyName: "Daniels",
            carePlanUUID: carePlanUUIDs[.mentalHealth]
        )
        contact1.title = "Family Practice Doctor"
        contact1.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@uky.edu")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(800) 257-2000")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(800) 357-2040")]
        contact1.address = {
            let address = OCKPostalAddress(
				street: "1500 San Pablo St",
				city: "Los Angeles",
				state: "CA",
				postalCode: "90033",
				country: "US"
			)
            return address
        }()

        var contact2 = OCKContact(
            id: "matthew",
            givenName: "Matthew",
            familyName: "Reiff",
            carePlanUUID: carePlanUUIDs[.mentalHealth]
        )
        contact2.title = "OBGYN"
        contact2.role = "Dr. Reiff is an OBGYN with 13 years of experience."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(800) 257-1000")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(800) 257-1234")]
        contact2.address = {
			let address = OCKPostalAddress(
				street: "1500 San Pablo St",
				city: "Los Angeles",
				state: "CA",
				postalCode: "90033",
				country: "US"
			)
            return address
        }()

        _ = try await addContactsIfNotPresent(
            [
                contact1,
                contact2
            ]
        )
    }
    func createQualityOfLifeSurveyTask(carePlanUUID: UUID?) -> OCKTask {
        let qualityOfLifeTaskId = TaskID.qualityOfLife
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!

        let qualityOfLifeElement = OCKScheduleElement(
            start: beforeBreakfast,
            end: nil,
            interval: DateComponents(day: 1)
        )
        let qualityOfLifeSchedule = OCKSchedule(composing: [qualityOfLifeElement])

        let textChoiceYesText = String(localized: "ANSWER_YES")
        let textChoiceNoText = String(localized: "ANSWER_NO")
        let choices: [TextChoice] = [
            .init(id: "\(qualityOfLifeTaskId)_0", choiceText: textChoiceYesText, value: "Yes"),
            .init(id: "\(qualityOfLifeTaskId)_1", choiceText: textChoiceNoText, value: "No")
        ]

        let questionOne = SurveyQuestion(
            id: "\(qualityOfLifeTaskId)-managing-time",
            type: .multipleChoice,
            required: true,
            title: String(localized: "QUALITY_OF_LIFE_TIME"),
            textChoices: choices,
            choiceSelectionLimit: .single
        )

        let questionTwo = SurveyQuestion(
            id: "\(qualityOfLifeTaskId)-stress",
            type: .slider,
            required: false,
            title: String(localized: "QUALITY_OF_LIFE_STRESS"),
            detail: String(localized: "QUALITY_OF_LIFE_STRESS_DETAIL"),
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let questionThree = SurveyQuestion(
            id: "\(qualityOfLifeTaskId)-sleep",
            type: .slider,
            required: false,
            title: String(localized: "QUALITY_OF_LIFE_SLEEP"),
            detail: String(localized: "QUALITY_OF_LIFE_SLEEP_DETAIL"),
            integerRange: 0...10,
            sliderStepValue: 1
        )

        // 4. NEW: Energy Levels (Scale/Slider)
        let questionFour = SurveyQuestion(
            id: "\(qualityOfLifeTaskId)-energy",
            type: .slider,
            required: false,
            title: String(localized: "QUALITY_OF_LIFE_ENERGY"),
            detail: String(localized: "QUALITY_OF_LIFE_ENERGY_DETAIL"),
            integerRange: 0...5,
            sliderStepValue: 1
        )

        // 5. NEW: Social Interaction (Multiple Choice)
        let questionFive = SurveyQuestion(
            id: "\(qualityOfLifeTaskId)-social",
            type: .multipleChoice,
            required: true,
            title: String(localized: "QUALITY_OF_LIFE_SOCIAL"),
            textChoices: choices,
            choiceSelectionLimit: .single
        )

        // Bundle all questions into the step
        let questions = [questionOne, questionTwo, questionThree, questionFour, questionFive]

        let stepOne = SurveyStep(
            id: "\(qualityOfLifeTaskId)-step-1",
            questions: questions
        )

        // --- Task Creation ---
        var qualityOfLife = OCKTask(
            id: "\(qualityOfLifeTaskId)-stress", // Note: Consider using just qualityOfLifeTaskId
            title: String(localized: "Quality of Life"),
            carePlanUUID: carePlanUUID,
            schedule: qualityOfLifeSchedule
        )

        qualityOfLife.impactsAdherence = true
        qualityOfLife.asset = "brain.head.profile"
        qualityOfLife.card = .survey
        qualityOfLife.surveySteps = [stepOne]
        qualityOfLife.priority = 1

        return qualityOfLife
    }

    func addOnboardingTask(_ carePlanUUID: UUID? = nil) async throws -> [OCKTask] {

        let onboardSchedule = OCKSchedule.dailyAtTime(
            hour: 0, minutes: 0,
            start: Date(), end: nil,
            text: "Task Due!",
            duration: .allDay
        )

        var onboardTask = OCKTask(
            id: Onboard.identifier(),
            title: "Onboard",
            carePlanUUID: carePlanUUID,
            schedule: onboardSchedule
        )
        onboardTask.instructions = "You'll need to agree to some terms and conditions before we get started!"
        onboardTask.impactsAdherence = false
        onboardTask.card = .uiKitSurvey
        onboardTask.uiKitSurvey = .onboard

        return try await addTasksIfNotPresent([onboardTask])
    }

    func addUIKitSurveyTasks(_ carePlanUUID: UUID? = nil) async throws -> [OCKTask] {
            let thisMorning = Calendar.current.startOfDay(for: Date())

            let nextWeek = Calendar.current.date(
                byAdding: .weekOfYear,
                value: 1,
                to: Date()
            )!

            let nextMonth = Calendar.current.date(
                byAdding: .month,
                value: 1,
                to: thisMorning
            )

            let dailyElement = OCKScheduleElement(
                start: thisMorning,
                end: nextWeek,
                interval: DateComponents(day: 1),
                text: nil,
                targetValues: [],
                duration: .allDay
            )

            let weeklyElement = OCKScheduleElement(
                start: nextWeek,
                end: nextMonth,
                interval: DateComponents(weekOfYear: 1),
                text: nil,
                targetValues: [],
                duration: .allDay
            )

            let rangeOfMotionCheckSchedule = OCKSchedule(
                composing: [dailyElement, weeklyElement]
            )

            var rangeOfMotionTask = OCKTask(
                id: RangeOfMotion.identifier(),
                title: "Range Of Motion",
                carePlanUUID: carePlanUUID,
                schedule: rangeOfMotionCheckSchedule
            )
            rangeOfMotionTask.priority = 2
            rangeOfMotionTask.asset = "figure.walk.motion"
            rangeOfMotionTask.card = .uiKitSurvey
            rangeOfMotionTask.uiKitSurvey = .rangeOfMotion

            return try await addTasksIfNotPresent([rangeOfMotionTask])
        }
}
