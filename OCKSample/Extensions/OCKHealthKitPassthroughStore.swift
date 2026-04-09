//
//  OCKHealthKitPassthroughStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitEssentials
import CareKitStore
import HealthKit
import os.log

extension OCKHealthKitPassthroughStore {

    func populateDefaultHealthKitTasks(
        _ patientUUID: UUID? = nil,
        startDate: Date = Date()
	) async throws {

        let carePlanUUIDs = try await OCKStore.getCarePlanUUIDs()

        let countUnit = HKUnit.count()
        let sleepResultTargetValue = OCKOutcomeValue(
            8.0,
            units: countUnit.unitString
        )
        let sleepResultTargetValues = [ sleepResultTargetValue ]
        let sleepResultSchedule = OCKSchedule.dailyAtTime(
            hour: 0,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: sleepResultTargetValues
        )
        var sleepResult = OCKHealthKitTask(
            id: TaskID.sleepResult,
            title: String(localized: "SLEEP_RESULT"),
            carePlanUUID: carePlanUUIDs[.sleepHealth],
            schedule: sleepResultSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                categoryIdentifier: .sleepAnalysis
            )
        )
        sleepResult.asset = "figure.walk"
        sleepResult.card = .labeledValue
        sleepResult.priority = 0
        sleepResult.impactsAdherence = false

        let ovulationTestResultSchedule = OCKSchedule.dailyAtTime(
            hour: 8,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: []
        )
        var ovulationTestResult = OCKHealthKitTask(
            id: TaskID.ovulationTestResult,
            title: String(localized: "OVULATION_TEST_RESULT"),
            carePlanUUID: carePlanUUIDs[.wellness],
            schedule: ovulationTestResultSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                categoryIdentifier: .ovulationTestResult
            )
        )
        ovulationTestResult.asset = "circle.dotted"
        ovulationTestResult.card = .labeledValue
        ovulationTestResult.priority = 1
        ovulationTestResult.impactsAdherence = false

        let tasks = [ sleepResult, ovulationTestResult ]

        _ = try await addTasksIfNotPresent(tasks)

    }
}
