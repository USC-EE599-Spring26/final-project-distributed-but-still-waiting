//
//  Utility+SleepSync.swift
//  OCKSample
//
//  Created by Student on 5/28/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import HealthKit
import os.log

#if os(iOS) || os(visionOS)

extension Utility {
	static func syncSleepHours(
		for date: Date = Date()
	) async {
		guard HKHealthStore.isHealthDataAvailable() else {
			return
		}

		do {
			let interval = try makeDayInterval(for: date)
			let sleepHours = try await fetchSleepHours(during: interval)
			try await saveSleepHours(
				sleepHours,
				for: interval
			)
		} catch {
			Logger.utility.error("Failed to sync sleep hours: \(error)")
		}
	}

	private static func makeDayInterval(
		for date: Date
	) throws -> DateInterval {
		guard let interval = Calendar.current.dateInterval(
			of: .day,
			for: date
		) else {
			throw OCKStoreError.invalidValue(
				reason: "Unable to create a day interval for sleep sync"
			)
		}

		return interval
	}

	private static func fetchSleepHours(
		during interval: DateInterval
	) async throws -> Double {
		let asleepIntervals = try await fetchAsleepIntervals(
			during: interval
		)
		let mergedIntervals = mergeOverlappingIntervals(
			asleepIntervals
		)
		let totalDuration = mergedIntervals.reduce(0) { result, dateInterval in
			result + dateInterval.duration
		}
		return totalDuration / 3600
	}

	private static func fetchAsleepIntervals(
		during interval: DateInterval
	) async throws -> [DateInterval] {
		guard let sleepType = HKObjectType.categoryType(
			forIdentifier: .sleepAnalysis
		) else {
			return []
		}

		let predicate = HKQuery.predicateForSamples(
			withStart: interval.start,
			end: interval.end,
			options: []
		)
		let sortDescriptors = [
			NSSortDescriptor(
				key: HKSampleSortIdentifierStartDate,
				ascending: true
			)
		]
		let healthStore = HKHealthStore()

		return try await withCheckedThrowingContinuation { continuation in
			let query = HKSampleQuery(
				sampleType: sleepType,
				predicate: predicate,
				limit: HKObjectQueryNoLimit,
				sortDescriptors: sortDescriptors
			) { _, samples, error in
				if let error {
					continuation.resume(throwing: error)
					return
				}

				let intervals = (samples as? [HKCategorySample] ?? [])
					.filter(Self.isAsleepSample)
					.compactMap { sample in
						Self.clippedInterval(
							for: sample,
							within: interval
						)
					}

				continuation.resume(returning: intervals)
			}

			healthStore.execute(query)
		}
	}

	@MainActor
	private static func saveSleepHours(
		_ sleepHours: Double,
		for interval: DateInterval
	) async throws {
		guard let store = AppDelegateKey.defaultValue?.store else {
			throw AppError.couldntBeUnwrapped
		}

		var query = OCKEventQuery(dateInterval: interval)
		query.taskIDs = [TaskID.sleepResult]
		let events = try await store.fetchEvents(query: query)

		guard let event = events.first else {
			Logger.utility.warning("No sleep event found for interval: \(interval)")
			return
		}

		var outcomeValue = OCKOutcomeValue(
			sleepHours,
			units: HKUnit.hour().unitString
		)
		outcomeValue.kind = "sleepHours"
		outcomeValue.createdDate = interval.start

		if var outcome = event.outcome {
			if outcome.values.first?.doubleValue == sleepHours &&
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

	private static func mergeOverlappingIntervals(
		_ intervals: [DateInterval]
	) -> [DateInterval] {
		guard let firstInterval = intervals.first else {
			return []
		}

		return intervals.dropFirst().reduce(
			into: [firstInterval]
		) { result, currentInterval in
			guard let lastInterval = result.last else {
				result.append(currentInterval)
				return
			}

			if currentInterval.start <= lastInterval.end {
				result[result.count - 1] = DateInterval(
					start: lastInterval.start,
					end: max(lastInterval.end, currentInterval.end)
				)
				return
			}

			result.append(currentInterval)
		}
	}

	private static func isAsleepSample(
		_ sample: HKCategorySample
	) -> Bool {
		guard let sleepValue = HKCategoryValueSleepAnalysis(
			rawValue: sample.value
		) else {
			return false
		}

		return HKCategoryValueSleepAnalysis.allAsleepValues.contains(
			sleepValue
		)
	}

	private static func clippedInterval(
		for sample: HKCategorySample,
		within interval: DateInterval
	) -> DateInterval? {
		let clippedStart = max(sample.startDate, interval.start)
		let clippedEnd = min(sample.endDate, interval.end)

		guard clippedStart < clippedEnd else {
			return nil
		}

		return DateInterval(
			start: clippedStart,
			end: clippedEnd
		)
	}
}

#endif
