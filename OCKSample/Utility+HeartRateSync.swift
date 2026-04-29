//
//  Utility+HeartRateSync.swift
//  OCKSample
//
//  Created by Student on 4/29/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import HealthKit
import os.log

#if os(iOS) || os(visionOS)

enum HeartRateOutcomeKind {
    static let average = "averageHeartRate"
}

extension Utility {
    static func syncHeartRate(
        for date: Date = Date()
    ) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        do {
            let interval = try makeDayIntervalForHR(for: date)
            let avgHeartRate = try await fetchAverageHeartRate(during: interval)
            guard let avgHeartRate = avgHeartRate else { return } // No data
            try await saveHeartRate(
                avgHeartRate,
                for: interval
            )
        } catch {
            Logger.utility.error("Failed to sync heart rate: \(error)")
        }
    }

    private static func makeDayIntervalForHR(
        for date: Date
    ) throws -> DateInterval {
        guard let interval = Calendar.current.dateInterval(
            of: .day,
            for: date
        ) else {
            throw OCKStoreError.invalidValue(
                reason: "Unable to create a day interval for heart rate sync"
            )
        }
        return interval
    }

    private static func fetchAverageHeartRate(
        during interval: DateInterval
    ) async throws -> Double? {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end,
            options: .strictStartDate
        )

        let healthStore = HKHealthStore()

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let averageQuantity = result?.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let unit = HKUnit.count().unitDivided(by: .minute())
                let avgValue = averageQuantity.doubleValue(for: unit)
                continuation.resume(returning: avgValue)
            }
            healthStore.execute(query)
        }
    }

    @MainActor
    private static func saveHeartRate(
        _ avgHeartRate: Double,
        for interval: DateInterval
    ) async throws {
        guard let store = AppDelegateKey.defaultValue?.store else {
            throw AppError.couldntBeUnwrapped
        }

        var query = OCKEventQuery(dateInterval: interval)
        query.taskIDs = [TaskID.heartRate]
        let events = try await store.fetchEvents(query: query)

        guard let event = events.first else {
            Logger.utility.warning("No heart rate event found for interval: \(interval)")
            return
        }

        var outcomeValue = OCKOutcomeValue(
            avgHeartRate,
            units: "bpm"
        )
        outcomeValue.kind = HeartRateOutcomeKind.average
        outcomeValue.createdDate = interval.start

        if var outcome = event.outcome {
            if outcome.values.first?.doubleValue == avgHeartRate &&
                outcome.values.first?.units == outcomeValue.units {
                return
            }

            outcome.values = [outcomeValue]
            outcome.effectiveDate = interval.start
            _ = try await store.updateOutcome(outcome)
            return
        }

        var outcome = OCKOutcome(
            taskUUID: event.task.uuid,
            taskOccurrenceIndex: event.scheduleEvent.occurrence,
            values: [outcomeValue]
        )
        outcome.effectiveDate = interval.start
        _ = try await store.addOutcome(outcome)
    }
}

#endif
