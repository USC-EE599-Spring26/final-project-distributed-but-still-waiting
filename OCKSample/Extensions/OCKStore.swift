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
        lexapro.card = .checklist
        lexapro.priority = 1

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
        cbtExercises.card = .instruction
        cbtExercises.priority = 2

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
        depression.card = .instruction
        depression.priority = 3

        let energyElement = OCKScheduleElement(
            start: beforeBreakfast,
            end: nil,
            interval: DateComponents(hour: 3)
        )
        let energySchedule = OCKSchedule(
            composing: [energyElement]
        )
        var energy = OCKTask(
            id: TaskID.energy,
            title: String(localized: "ENERGY"),
            carePlanUUID: nil,
            schedule: energySchedule
        )
        energy.impactsAdherence = true
        energy.asset = "figure.flexibility"
        energy.priority = 4
        energy.card = .customEnergy

        let ph9 = createPH9SurveyTask(carePlanUUID: nil)

        _ = try await addTasksIfNotPresent(
            [
                depression,
                lexapro,
                cbtExercises,
                energy,
                ph9
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
        let qualityOfLifeSchedule = OCKSchedule(
            composing: [qualityOfLifeElement]
        )
        let textChoiceYesText = String(localized: "ANSWER_YES")
        let textChoiceNoText = String(localized: "ANSWER_NO")
        let yesValue = "Yes"
        let noValue = "No"
        let choices: [TextChoice] = [
            .init(
                id: "\(qualityOfLifeTaskId)_0",
                choiceText: textChoiceYesText,
                value: yesValue
            ),
            .init(
                id: "\(qualityOfLifeTaskId)_1",
                choiceText: textChoiceNoText,
                value: noValue
            )

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
            id: qualityOfLifeTaskId,
            type: .slider,
            required: false,
            title: String(localized: "QUALITY_OF_LIFE_STRESS"),
            detail: String(localized: "QUALITY_OF_LIFE_STRESS_DETAIL"),
            integerRange: 0...10,
            sliderStepValue: 1
        )
        let questions = [questionOne, questionTwo]
        let stepOne = SurveyStep(
            id: "\(qualityOfLifeTaskId)-step-1",
            questions: questions
        )
        var qualityOfLife = OCKTask(
            id: "\(qualityOfLifeTaskId)-stress",
            title: String(localized: "QUALITY_OF_LIFE"),
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

    func createPH9SurveyTask(carePlanUUID: UUID?) -> OCKTask {
        let ph9SurveyTaskId = TaskID.ph9
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let ph9Element = OCKScheduleElement(
            start: beforeBreakfast,
            end: nil,
            interval: DateComponents(day: 1)
        )
        let ph9SurveySchedule = OCKSchedule(
            composing: [ph9Element]
        )
        let textChoiceDifficultText = String(localized: "ANSWER_DIFFICULT")
        let textChoiceNotDifficultText = String(localized: "ANSWER_NOT_DIFFICULT")
        let difficultValue = "Difficult"
        let notDifficultValue = "NotDifficult"
        let choices: [TextChoice] = [
            .init(
                id: "\(ph9SurveyTaskId)_0",
                choiceText: textChoiceDifficultText,
                value: difficultValue
            ),
            .init(
                id: "\(ph9SurveyTaskId)_1",
                choiceText: textChoiceNotDifficultText,
                value: notDifficultValue
            )

        ]
        let questionOne = SurveyQuestion(
            id: "\(ph9SurveyTaskId)-q1",
            type: .slider,
            required: false,
            title: String(localized: "PH9_QUESTION1"),
            integerRange: 0...3,
            sliderStepValue: 1
        )
        let questionTwo = SurveyQuestion(
            id: "\(ph9SurveyTaskId)-q2",
            type: .slider,
            required: false,
            title: String(localized: "PH9_QUESTION2"),
            integerRange: 0...3,
            sliderStepValue: 1
        )
        let questionThree = SurveyQuestion(
            id: "\(ph9SurveyTaskId)-q3",
            type: .slider,
            required: false,
            title: String(localized: "PH9_QUESTION3"),
            integerRange: 0...3,
            sliderStepValue: 1
        )
        let questionFour = SurveyQuestion(
            id: "\(ph9SurveyTaskId)-q4",
            type: .multipleChoice,
            required: true,
            title: String(localized: "PH9_LAST_QUESTION"),
            textChoices: choices,
            choiceSelectionLimit: .single
        )
        let questions = [questionOne, questionTwo, questionThree, questionFour]
        let stepOne = SurveyStep(
            id: "\(ph9SurveyTaskId)-step-1",
            questions: questions
        )
        var ph9Survey = OCKTask(
            id: "\(ph9SurveyTaskId)-ph9",
            title: String(localized: "PH9_SURVEY"),
            carePlanUUID: carePlanUUID,
            schedule: ph9SurveySchedule
        )
        ph9Survey.impactsAdherence = true
        ph9Survey.asset = "brain.head.profile"
        ph9Survey.card = .survey
        ph9Survey.surveySteps = [stepOne]
        ph9Survey.priority = 1

        return ph9Survey
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
