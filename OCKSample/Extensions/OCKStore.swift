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
import HealthKit
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
        // Mental Health Care Plan — antidepressant medication adherence.
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
            title: String(localized: "THOUGHT_RECORD"),
            carePlanUUID: carePlanUUIDs[.mentalHealth],
            schedule: cbtExerciseSchedule
        )
        cbtExercises.impactsAdherence = true
        cbtExercises.instructions = String(localized: "THOUGHT_RECORD_INSTRUCTIONS")
        cbtExercises.asset = "brain.head.profile"
        cbtExercises.card = .instruction
        // Mental Health Care Plan — daily CBT thought record.
        cbtExercises.priority = 3

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
        // Mental Health Care Plan — daily mood self-report.
        depression.priority = 2

        let energyElement = OCKScheduleElement(
            start: beforeBreakfast,
            end: nil,
            interval: DateComponents(day: 1)
        )
        let energySchedule = OCKSchedule(
            composing: [energyElement]
        )
        let sleepSchedule = OCKSchedule.dailyAtTime(
            hour: 0,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: [
                OCKOutcomeValue(
                    8.0,
                    units: HKUnit.hour().unitString
                )
            ]
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
        // Sleep Health Care Plan — morning reflection on energy level.
        energy.priority = 8
        energy.card = .twoButton
        energy.userInfo?[Constants.twoButtonPositiveTitleKey] = "HIGH_ENERGY"
        energy.userInfo?[Constants.twoButtonNegativeTitleKey] = "LOW_ENERGY"

        var sleepResult = OCKTask(
            id: TaskID.sleepResult,
            title: String(localized: "SLEEP_RESULT"),
            carePlanUUID: carePlanUUIDs[.sleepHealth],
            schedule: sleepSchedule
        )
        sleepResult.instructions = String(localized: "SLEEP_RESULT_INSTRUCTIONS")
        sleepResult.asset = "bed.double.fill"
        sleepResult.card = .numericProgress
        // Sleep Health Care Plan — overnight sleep duration tracking.
        sleepResult.priority = 7
        sleepResult.impactsAdherence = false

        let heartRateSchedule = OCKSchedule.dailyAtTime(
            hour: 0,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil
        )
        var heartRate = OCKTask(
            id: TaskID.heartRate,
            title: String(localized: "HEART_RATE"),
            carePlanUUID: carePlanUUIDs[.stressReduction],
            schedule: heartRateSchedule
        )
        heartRate.instructions = String(localized: "HEART_RATE_INSTRUCTIONS")
        heartRate.asset = "heart.fill"
        heartRate.card = .heartRate
        // Stress Reduction Care Plan — physiological stress indicator (HRV).
        heartRate.priority = 11
        heartRate.impactsAdherence = false

        let bedtimeChecklistElements = [
            String(localized: "DIM_THE_LIGHTS"),
            String(localized: "NO_SCREENS"),
            String(localized: "TAKE_A_WARM_SHOWER"),
            String(localized: "READ_FOR_10_MINUTES"),
            String(localized: "MEDITATION")
        ].map { text in
            OCKScheduleElement(
                start: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: thisMorning) ?? thisMorning,
                end: nil,
                interval: DateComponents(day: 1),
                text: text,
                targetValues: [],
                duration: .allDay
            )
        }
        let bedtimeChecklistSchedule = OCKSchedule(composing: bedtimeChecklistElements)
        var bedtimeChecklist = OCKTask(
            id: TaskID.bedtimeChecklist,
            title: String(localized: "BEDTIME_CHECKLIST"),
            carePlanUUID: carePlanUUIDs[.sleepHealth],
            schedule: bedtimeChecklistSchedule
        )
        bedtimeChecklist.impactsAdherence = true
        bedtimeChecklist.instructions = String(localized: "BEDTIME_CHECKLIST_INSTRUCTIONS")
        bedtimeChecklist.card = .checklist
        bedtimeChecklist.asset = "moon.stars.fill"
        // Sleep Health Care Plan — evening wind-down routine.
        bedtimeChecklist.priority = 6

        let panicAttackSchedule = OCKSchedule(
            composing: [
                OCKScheduleElement(
                    start: thisMorning,
                    end: nil,
                    interval: DateComponents(day: 1),
                    text: String(localized: "ANYTIME_DURING_DAY"),
                    targetValues: [],
                    duration: .allDay
                )
            ]
        )

        var panicAttack = OCKTask(
            id: TaskID.panicAttack,
            title: String(localized: "PANIC_ATTACK"),
            carePlanUUID: carePlanUUIDs[.mentalHealth],
            schedule: panicAttackSchedule
        )
        panicAttack.impactsAdherence = false
        panicAttack.instructions = String(localized: "PANIC_ATTACK_INSTRUCTIONS")
        panicAttack.asset = "exclamationmark.triangle.fill"
        panicAttack.card = .button
        panicAttack.priority = 12

        let phq = createPHQSurveyTask(
            carePlanUUID: carePlanUUIDs[.mentalHealth],
            startDate: startDate
        )

        try await migrateSleepTaskIfNeeded(
            sleepTaskID: TaskID.sleepResult
        )

        _ = try await addTasksIfNotPresent(
            [
                depression,
                lexapro,
                cbtExercises,
                energy,
                sleepResult,
                heartRate,
                bedtimeChecklist,
                phq,
                panicAttack
            ]
        )

        _ = try await addOnboardingTask(nil)
        _ = try await addUIKitSurveyTasks(
            mentalHealthCarePlanUUID: carePlanUUIDs[.mentalHealth],
            stressReductionCarePlanUUID: carePlanUUIDs[.stressReduction]
        )

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

    func createPHQSurveyTask(
        carePlanUUID: UUID?,
        startDate: Date = Date()
    ) -> OCKTask {
        let phqSurveyTaskId = TaskID.phq9Survey
        let thisMorning = Calendar.current.startOfDay(for: startDate)
        let phqElement = OCKScheduleElement(
            start: thisMorning,
            end: nil,
            interval: DateComponents(weekOfYear: 1),
            text: String(localized: "ANYTIME_DURING_DAY"),
            targetValues: [],
            duration: .allDay
        )
        let phqSurveySchedule = OCKSchedule(
            composing: [phqElement]
        )
        var phqSurvey = OCKTask(
            id: phqSurveyTaskId,
            title: String(localized: "PHQ9_TASK_TITLE"),
            carePlanUUID: carePlanUUID,
            schedule: phqSurveySchedule
        )
        phqSurvey.impactsAdherence = true
        phqSurvey.instructions = String(localized: "PHQ9_TASK_INSTRUCTIONS")
        phqSurvey.asset = "brain.head.profile"
        phqSurvey.card = .uiKitSurvey
        phqSurvey.uiKitSurvey = .phq9
        // Mental Health Care Plan — weekly clinical depression scale.
        phqSurvey.priority = 4

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

    func addUIKitSurveyTasks(
        mentalHealthCarePlanUUID: UUID? = nil,
        stressReductionCarePlanUUID: UUID? = nil
    ) async throws -> [OCKTask] {
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

        let stroopSchedule = OCKSchedule(
            composing: [
                OCKScheduleElement(
                    start: thisMorning,
                    end: nil,
                    interval: DateComponents(day: 1),
                    text: nil,
                    targetValues: [],
                    duration: .allDay
                )
            ]
        )

        // Mental Health Care Plan — daily cognitive flexibility / attention check.
        var stroopTask = OCKTask(
            id: TaskID.stroop,
            title: String(localized: "STROOP_TASK_TITLE_CUSTOM"),
            carePlanUUID: mentalHealthCarePlanUUID,
            schedule: stroopSchedule
        )
        stroopTask.priority = 5
        stroopTask.instructions = String(localized: "STROOP_TASK_INSTRUCTIONS_CUSTOM")
        stroopTask.asset = "brain.head.profile"
        stroopTask.card = .uiKitSurvey
        stroopTask.uiKitSurvey = .stroop
        stroopTask.impactsAdherence = true

        // Stress Reduction Care Plan — physical mobility / tension release.
        var rangeOfMotionTask = OCKTask(
            id: RangeOfMotion.identifier(),
            title: String(localized: "RANGE_OF_MOTION"),
            carePlanUUID: stressReductionCarePlanUUID,
            schedule: rangeOfMotionCheckSchedule
        )
        rangeOfMotionTask.priority = 10
        rangeOfMotionTask.instructions = String(localized: "RANGE_OF_MOTION_INSTRUCTIONS")
        rangeOfMotionTask.asset = "figure.walk.motion"
        rangeOfMotionTask.card = .uiKitSurvey
        rangeOfMotionTask.uiKitSurvey = .rangeOfMotion
        rangeOfMotionTask.impactsAdherence = true

        // Stress Reduction Care Plan — daily relaxation practice.
        var guidedMeditationTask = OCKTask(
            id: GuidedMeditation.identifier(),
            title: String(localized: "GUIDED_MEDITATION"),
            carePlanUUID: stressReductionCarePlanUUID,
            schedule: stroopSchedule
        )
        guidedMeditationTask.priority = 9
        guidedMeditationTask.instructions = String(localized: "TAKE_MOMENT_RELAX")
        guidedMeditationTask.asset = "wind"
        guidedMeditationTask.card = .uiKitSurvey
        guidedMeditationTask.uiKitSurvey = .guidedMeditation
        guidedMeditationTask.impactsAdherence = true

        return try await addTasksIfNotPresent([stroopTask, rangeOfMotionTask, guidedMeditationTask])
    }

    private func migrateSleepTaskIfNeeded(
        sleepTaskID: String
    ) async throws {
        var query = OCKTaskQuery()
        query.ids = [sleepTaskID]
        let existingTasks = try await fetchAnyTasks(query: query)
        let healthKitSleepTasks = existingTasks.compactMap { task in
            task as? OCKHealthKitTask
        }

        guard !healthKitSleepTasks.isEmpty else {
            return
        }

        _ = try await deleteAnyTasks(healthKitSleepTasks)
    }
}
