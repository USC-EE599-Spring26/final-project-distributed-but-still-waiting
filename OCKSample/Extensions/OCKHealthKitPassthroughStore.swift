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
		startDate: Date = Date()
	) async throws {

        let countUnit = HKUnit.count()
        let sleepDurationTargetValue = OCKOutcomeValue(
            8.0,
            units: countUnit.unitString
        )
        let sleepDurationTargetValues = [ sleepDurationTargetValue ]
        let sleepDurationSchedule = OCKSchedule.dailyAtTime(
            hour: 0,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: sleepDurationTargetValues
        )
        var sleepDuration = OCKHealthKitTask(
            id: TaskID.sleepDuration,
            title: String(localized: "sleepDuration"),
            carePlanUUID: nil,
            schedule: sleepDurationSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .stepCount,
                quantityType: .cumulative,
                unit: countUnit
            )
        )
        sleepDuration.asset = "figure.walk"

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
            carePlanUUID: nil,
            schedule: ovulationTestResultSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                categoryIdentifier: .ovulationTestResult
            )
        )
        ovulationTestResult.asset = "circle.dotted"
        let tasks = [ sleepDuration, ovulationTestResult ]

        _ = try await addTasksIfNotPresent(tasks)

    }
}
