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

	func addCarePlansIfNotPresent(
		_ carePlans: [OCKAnyCarePlan],
		patientUUID: UUID? = nil
	) async throws {
		let carePlanIdsToAdd = carePlans.compactMap { $0.id }

		// Prepare query to see if Care Plan are already added
		var query = OCKCarePlanQuery(for: Date())
		query.ids = carePlanIdsToAdd
		let foundCarePlans = try await self.fetchAnyCarePlans(query: query)

		// All existing care plans added already
		let existingCarePlanIDs = Set(foundCarePlans.map { $0.id })

		// Compare existing carePlans to the carePlans that may not have been added
		let carePlansNotInStore = carePlans.compactMap { carePlan -> OCKAnyCarePlan? in
			guard !existingCarePlanIDs.contains(carePlan.id) else {return nil }

			// Cast care plan to OCKCarePlan if the careplan is not in the existingCarePlans
			if var tempCarePlan = carePlan as? OCKCarePlan {
				tempCarePlan.patientUUID = patientUUID
				return tempCarePlan
			}

			// Return casted carePlan
			return carePlan
		}

		// Only add if there's a new Care Plan
		if carePlansNotInStore.count > 0 {
			do {
				_ = try await self.addAnyCarePlans(carePlansNotInStore)
				Logger.ockStore.info("Added Care Plans into OCKStore!")
			} catch {
				Logger.ockStore.error("Error adding Care Plans: \(error.localizedDescription)")
			}
		}
	}

	func addContactsIfNotPresent(_ contacts: [OCKContact]) async throws -> [OCKContact] {
		let contactIdsToAdd = contacts.compactMap { $0.id }

		// Prepare query to see if contacts are already added
		var query = OCKContactQuery(for: Date())
		query.ids = contactIdsToAdd

		let foundContacts = try await fetchContacts(query: query)

		// Find all missing tasks.

		// All current contacts in database
		let existingContacts = Set(foundContacts.map { $0.id })

		// Compare existing carePlans to the carePlans that may not have been added
		let contactsNotInStore = contacts.compactMap { contact -> OCKContact? in
			guard !existingContacts.contains(contact.id) else { return nil }
			return contact
		}

		// Only add if there's a new task
		guard contactsNotInStore.count > 0 else {
			return []
		}

		let addedContacts = try await addContacts(contactsNotInStore)
		return addedContacts
	}

	func populateCarePlans(patientUUID: UUID? = nil) async throws {
		let mentalHealthCarePlan = OCKCarePlan(
			id: CarePlanID.mentalHealth.rawValue,
			title: "Mental Health Care Plan",
			patientUUID: patientUUID
		)
		let sleepHealthCarePlan = OCKCarePlan(
			id: CarePlanID.sleepHealth.rawValue,
			title: "Sleep Health Care Plan",
			patientUUID: patientUUID
		)
		let stressReductionCarePlan = OCKCarePlan(
			id: CarePlanID.stressReduction.rawValue,
			title: "Stress Reduction Care Plan",
			patientUUID: patientUUID
		)
		try await addCarePlansIfNotPresent(
			[
			mentalHealthCarePlan,
			sleepHealthCarePlan,
			stressReductionCarePlan
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
		lexapro.impactsAdherence = true

		let cbtExerciseElement = OCKScheduleElement(
			start: beforeBreakfast,
			end: nil,
			interval: DateComponents(day: 1)
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
		cbtExercises.asset = "brain.head.profile"
		cbtExercises.card = .instruction
		cbtExercises.priority = 4

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
		depression.impactsAdherence = true
		depression.instructions = String(localized: "DEPRESSION_INSTRUCTIONS")
		depression.asset = "bed.double"
		depression.card = .instruction
		depression.priority = 7

		let energyElement = OCKScheduleElement(
			start: beforeBreakfast,
			end: nil,
			interval: DateComponents(day: 1)
		)
		let energySchedule = OCKSchedule(
			composing: [energyElement]
		)
		var energy = OCKTask(
			id: TaskID.energy,
			title: String(localized: "ENERGY"),
			carePlanUUID: carePlanUUIDs[.sleepHealth],
			schedule: energySchedule
		)
		energy.impactsAdherence = true
		energy.instructions = String(localized: "ENERGY_INSTRUCTIONS")
		energy.asset = "figure.flexibility"
		energy.priority = 10
		energy.card = .twoButton
		energy.userInfo?[Constants.twoButtonPositiveTitleKey] = "HIGH_ENERGY"
		energy.userInfo?[Constants.twoButtonNegativeTitleKey] = "LOW_ENERGY"

		let phq = createPHQSurveyTask(carePlanUUID: carePlanUUIDs[.mentalHealth])

		_ = try await addTasksIfNotPresent(
			[
				depression,
				lexapro,
				cbtExercises,
				energy,
				phq
			]
		)

		_ = try await addOnboardingTask(nil)
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
			carePlanUUID: carePlanUUIDs[.sleepHealth]
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

//	func createQualityOfLifeSurveyTask(carePlanUUID: UUID?) -> OCKTask {
//		let qualityOfLifeTaskId = TaskID.qualityOfLife
//		let thisMorning = Calendar.current.startOfDay(for: Date())
//		let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
//		let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
//		let qualityOfLifeElement = OCKScheduleElement(
//			start: beforeBreakfast,
//			end: nil,
//			interval: DateComponents(day: 1)
//		)
//		let qualityOfLifeSchedule = OCKSchedule(
//			composing: [qualityOfLifeElement]
//		)
//		let textChoiceYesText = String(localized: "ANSWER_YES")
//		let textChoiceNoText = String(localized: "ANSWER_NO")
//		let yesValue = "Yes"
//		let noValue = "No"
//		let choices: [TextChoice] = [
//			.init(
//				id: "\(qualityOfLifeTaskId)_0",
//				choiceText: textChoiceYesText,
//				value: yesValue
//			),
//			.init(
//				id: "\(qualityOfLifeTaskId)_1",
//				choiceText: textChoiceNoText,
//				value: noValue
//			)
//
//		]
//		let questionOne = SurveyQuestion(
//			id: "\(qualityOfLifeTaskId)-managing-time",
//			type: .multipleChoice,
//			required: true,
//			title: String(localized: "QUALITY_OF_LIFE_TIME"),
//			textChoices: choices,
//			choiceSelectionLimit: .single
//		)
//		let questionTwo = SurveyQuestion(
//			id: qualityOfLifeTaskId,
//			type: .slider,
//			required: false,
//			title: String(localized: "QUALITY_OF_LIFE_STRESS"),
//			detail: String(localized: "QUALITY_OF_LIFE_STRESS_DETAIL"),
//			integerRange: 0...10,
//			sliderStepValue: 1
//		)
//		let questions = [questionOne, questionTwo]
//		let stepOne = SurveyStep(
//			id: "\(qualityOfLifeTaskId)-step-1",
//			questions: questions
//		)
//		var qualityOfLife = OCKTask(
//			id: "\(qualityOfLifeTaskId)-stress",
//			title: String(localized: "QUALITY_OF_LIFE"),
//			carePlanUUID: carePlanUUID,
//			schedule: qualityOfLifeSchedule
//		)
//		qualityOfLife.impactsAdherence = true
//		qualityOfLife.asset = "brain.head.profile"
//		qualityOfLife.card = .survey
//		qualityOfLife.surveySteps = [stepOne]
//		qualityOfLife.priority = 1
//
//		return qualityOfLife
//	}

	func createPHQSurveyTask(carePlanUUID: UUID?) -> OCKTask {
		let phqSurveyTaskId = TaskID.phq
		let thisMorning = Calendar.current.startOfDay(for: Date())
		let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
		let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
		let phqElement = OCKScheduleElement(
			start: beforeBreakfast,
			end: nil,
			interval: DateComponents(day: 1)
		)
		let phqSurveySchedule = OCKSchedule(
			composing: [phqElement]
		)
		let textChoiceDifficultText = String(localized: "ANSWER_DIFFICULT")
		let textChoiceNotDifficultText = String(localized: "ANSWER_NOT_DIFFICULT")
		let difficultValue = "Difficult"
		let notDifficultValue = "NotDifficult"
		let choices: [TextChoice] = [
			.init(
				id: "\(phqSurveyTaskId)_0",
				choiceText: textChoiceDifficultText,
				value: difficultValue
			),
			.init(
				id: "\(phqSurveyTaskId)_1",
				choiceText: textChoiceNotDifficultText,
				value: notDifficultValue
			)

		]
		let questionOne = SurveyQuestion(
			id: "\(phqSurveyTaskId)-q1",
			type: .slider,
			required: false,
			title: String(localized: "PHQ_QUESTION1"),
			integerRange: 0...3,
			sliderStepValue: 1
		)
		let questionTwo = SurveyQuestion(
			id: "\(phqSurveyTaskId)-q2",
			type: .slider,
			required: false,
			title: String(localized: "PHQ_QUESTION2"),
			integerRange: 0...3,
			sliderStepValue: 1
		)
		let questionThree = SurveyQuestion(
			id: "\(phqSurveyTaskId)-q3",
			type: .slider,
			required: false,
			title: String(localized: "PHQ_QUESTION3"),
			integerRange: 0...3,
			sliderStepValue: 1
		)
		let questionFour = SurveyQuestion(
			id: "\(phqSurveyTaskId)-q4",
			type: .multipleChoice,
			required: true,
			title: String(localized: "PHQ_LAST_QUESTION"),
			textChoices: choices,
			choiceSelectionLimit: .single
		)
		let questions = [questionOne, questionTwo, questionThree, questionFour]
		let stepOne = SurveyStep(
			id: "\(phqSurveyTaskId)-step-1",
			questions: questions
		)
		var phqSurvey = OCKTask(
			id: "\(phqSurveyTaskId)-phq",
			title: String(localized: "PHQ_SURVEY"),
			carePlanUUID: carePlanUUID,
			schedule: phqSurveySchedule
		)
		phqSurvey.impactsAdherence = true
		phqSurvey.instructions = String(localized: "PHQ_INSTRUCTIONS")
		phqSurvey.asset = "brain.head.profile"
		phqSurvey.card = .survey
		phqSurvey.surveySteps = [stepOne]
		phqSurvey.priority = 13

		return phqSurvey
	}

	func addOnboardingTask(_ carePlanUUID: UUID? = nil) async throws -> [OCKTask] {

		let onboardSchedule = OCKSchedule.dailyAtTime(
			hour: 0, minutes: 0,
			start: Date(), end: nil,
			text: String(localized: "TASK_DUE"),
			duration: .allDay
		)

		var onboardTask = OCKTask(
			id: Onboard.identifier(),
			title: String(localized: "ONBOARD"),
			carePlanUUID: carePlanUUID,
			schedule: onboardSchedule
		)
		onboardTask.instructions = String(localized: "ONBOARD_INSTRUCTIONS")
		onboardTask.impactsAdherence = false
		onboardTask.priority = 0
		onboardTask.asset = "doc.text.fill"
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
			title: String(localized: "RANGE_OF_MOTION"),
			carePlanUUID: carePlanUUID,
			schedule: rangeOfMotionCheckSchedule
		)
		rangeOfMotionTask.priority = 19
		rangeOfMotionTask.instructions = String(localized: "RANGE_OF_MOTION_INSTRUCTIONS")
		rangeOfMotionTask.asset = "figure.walk.motion"
		rangeOfMotionTask.card = .uiKitSurvey
		rangeOfMotionTask.uiKitSurvey = .rangeOfMotion
		rangeOfMotionTask.impactsAdherence = true

		return try await addTasksIfNotPresent([rangeOfMotionTask])
	}
}
