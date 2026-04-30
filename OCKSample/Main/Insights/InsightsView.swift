//
//  InsightsView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/17/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI

struct InsightsView: View {

	@CareStoreFetchRequest(query: query()) private var events
	@State var intervalSelected = 0 // Default to week since chart isn't working for others.
	@State var chartInterval = DateInterval()
	@State var period: PeriodComponent = .day
	@State var sortedTaskIDs: [String: Int] = [:]

	var body: some View {
		NavigationStack {
			dateIntervalSegmentView
				.padding()
			ScrollView {
				VStack {
					ForEach(orderedEvents) { event in
						chartView(for: event.result)
					}
				}
				.padding()
			}
			.onAppear {
				let taskIDs = TaskID.orderedWatchOS + TaskID.orderedObjective
				sortedTaskIDs = computeTaskIDOrder(taskIDs: taskIDs)
				events.query.taskIDs = taskIDs
				events.query.dateInterval = eventQueryInterval
				setupChartPropertiesForSegmentSelection(intervalSelected)
			}
#if os(iOS)
			.onChange(of: intervalSelected) { _, intervalSegmentValue in
				setupChartPropertiesForSegmentSelection(intervalSegmentValue)
			}
#else
			.onChange(of: intervalSelected, initial: true) { _, newSegmentValue in
				setupChartPropertiesForSegmentSelection(newSegmentValue)
			}
#endif
		}
	}
}

private extension InsightsView {
	@ViewBuilder
	func chartView(for eventResult: OCKAnyEvent) -> some View {
		let dataStrategy = determineDataStrategy(for: eventResult.task.id)

		if eventResult.task.id == TaskID.phq9Survey {
			CareKitEssentialChartView(
				title: eventResult.title,
				subtitle: subtitle,
				dateInterval: $chartInterval,
				period: $period,
				configurations: phq9Configurations(for: eventResult.task.id)
			)
		} else if eventResult.task.id == TaskID.cbtExercises
			|| eventResult.task.id == TaskID.energy {
			CareKitEssentialChartView(
				title: eventResult.title,
				subtitle: subtitle,
				dateInterval: $chartInterval,
				period: $period,
				configurations: binaryOutcomeConfigurations(for: eventResult.task.id)
			)
        } else if eventResult.task.id == TaskID.energy {
            CareKitEssentialChartView(
                title: eventResult.title,
                subtitle: subtitle,
                dateInterval: $chartInterval,
                period: $period,
                configurations: energyOutcomeConfigurations(for: eventResult.task.id)
            )
        } else if eventResult.task.id == TaskID.sleepResult {
			CareKitEssentialChartView(
				title: eventResult.title,
				subtitle: subtitle,
				dateInterval: $chartInterval,
				period: $period,
				configurations: sleepConfigurations(for: eventResult.task.id)
			)
		} else if eventResult.task.id != TaskID.lexapro
			&& eventResult.task.id != TaskID.depression
			&& eventResult.task.id != TaskID.phq9Survey {
			CareKitEssentialChartView(
				title: eventResult.title,
				subtitle: subtitle,
				dateInterval: $chartInterval,
				period: $period,
				configurations: defaultConfigurations(
					for: eventResult.task.id,
					dataStrategy: dataStrategy
				)
			)
		} else if eventResult.task.id == TaskID.lexapro {
			CareKitEssentialChartView(
				title: String(localized: "DEPRESSION_LEXAPRO_INTAKE"),
				subtitle: subtitle,
				dateInterval: $chartInterval,
				period: $period,
				configurations: depressionAndLexaproConfigurations(
					for: eventResult.task.id
				)
			)
		}
	}

	func phq9Configurations(for taskID: String) -> [CKEDataSeriesConfiguration] {
		let averageConfiguration = CKEDataSeriesConfiguration(
			taskID: taskID,
			dataStrategy: .mean,
			kind: PHQ9OutcomeKind.totalScore,
			mark: .bar,
			legendTitle: String(localized: "AVERAGE"),
			showMarkWhenHighlighted: true,
			showMeanMark: false,
			showMedianMark: false,
			color: Color.accentColor,
			gradientStartColor: Color(TintColorFlipKey.defaultValue)
		) { event in
			event.computeProgress(
				by: .averagingOutcomeValues(
					kind: PHQ9OutcomeKind.totalScore
				)
			)
		}

		let totalConfiguration = CKEDataSeriesConfiguration(
			taskID: taskID,
			dataStrategy: .sum,
			kind: PHQ9OutcomeKind.totalScore,
			mark: .bar,
			legendTitle: String(localized: "TOTAL"),
			color: Color(TintColorFlipKey.defaultValue)
		) { event in
			event.computeProgress(
				by: .summingOutcomeValues(
					kind: PHQ9OutcomeKind.totalScore
				)
			)
		}

		return [
			averageConfiguration,
			totalConfiguration
		]
	}

	func binaryOutcomeConfigurations(for taskID: String) -> [CKEDataSeriesConfiguration] {
		let averageConfiguration = CKEDataSeriesConfiguration(
			taskID: taskID,
			dataStrategy: .mean,
			mark: .bar,
			legendTitle: String(localized: "AVERAGE"),
			showMarkWhenHighlighted: true,
			showMeanMark: false,
			showMedianMark: false,
			color: Color.accentColor,
			gradientStartColor: Color(TintColorFlipKey.defaultValue)
		) { event in
			binaryOutcomeProgress(
				for: event,
				taskID: taskID
			)
		}

		let totalConfiguration = CKEDataSeriesConfiguration(
			taskID: taskID,
			dataStrategy: .sum,
			mark: .bar,
			legendTitle: String(localized: "TOTAL"),
			color: Color(TintColorFlipKey.defaultValue)
		) { event in
			binaryOutcomeProgress(
				for: event,
				taskID: taskID
			)
		}

		return [
			averageConfiguration,
			totalConfiguration
		]
	}

	func binaryOutcomeProgress(
		for event: OCKAnyEvent,
		taskID: String
	) -> LinearCareTaskProgress {
		switch taskID {
		case TaskID.cbtExercises:
			return LinearCareTaskProgress(
				value: event.outcome == nil ? 0.0 : 1.0
			)
		case TaskID.energy:
			if let integerValue = event.outcome?.values.first?.integerValue {
				return LinearCareTaskProgress(
					value: Double(integerValue)
				)
			}

			if let doubleValue = event.outcome?.values.first?.doubleValue {
				return LinearCareTaskProgress(
					value: doubleValue
				)
			}

			return LinearCareTaskProgress(value: 0.0)
		default:
			return LinearCareTaskProgress(value: 0.0)
		}
	}

    func energyOutcomeConfigurations(for taskID: String) -> [CKEDataSeriesConfiguration] {
        let averageConfiguration = CKEDataSeriesConfiguration(
            taskID: taskID,
            dataStrategy: .mean,
            mark: .bar,
            legendTitle: String(localized: "AVERAGE"),
            showMarkWhenHighlighted: true,
            showMeanMark: false,
            showMedianMark: false,
            color: Color.accentColor,
            gradientStartColor: Color(TintColorFlipKey.defaultValue)
        ) { event in
            energyOutcomeProgress(for: event)
        }

        return [averageConfiguration]
    }

    func energyOutcomeProgress(for event: OCKAnyEvent) -> LinearCareTaskProgress {
        if let integerValue = event.outcome?.values.first?.integerValue {
            return LinearCareTaskProgress(value: Double(integerValue))
        }

        if let doubleValue = event.outcome?.values.first?.doubleValue {
            return LinearCareTaskProgress(value: doubleValue)
        }

        return LinearCareTaskProgress(value: 0.0)
    }

	func sleepConfigurations(for taskID: String) -> [CKEDataSeriesConfiguration] {
		let averageConfiguration = CKEDataSeriesConfiguration(
			taskID: taskID,
			dataStrategy: .mean,
			kind: "sleepHours",
			mark: .bar,
			legendTitle: String(localized: "AVERAGE"),
			showMarkWhenHighlighted: true,
			showMeanMark: false,
			showMedianMark: false,
			color: Color.accentColor,
			gradientStartColor: Color(TintColorFlipKey.defaultValue)
		) { event in
			event.computeProgress(
				by: .averagingOutcomeValues(kind: "sleepHours")
			)
		}

		let totalConfiguration = CKEDataSeriesConfiguration(
			taskID: taskID,
			dataStrategy: .sum,
			kind: "sleepHours",
			mark: .bar,
			legendTitle: String(localized: "TOTAL"),
			color: Color(TintColorFlipKey.defaultValue)
		) { event in
			event.computeProgress(
				by: .summingOutcomeValues(kind: "sleepHours")
			)
		}

		return [
			averageConfiguration,
			totalConfiguration
		]
	}

	func defaultConfigurations(
		for taskID: String,
		dataStrategy: CKEDataSeriesConfiguration.DataStrategy
	) -> [CKEDataSeriesConfiguration] {
		let meanGradientStart = Color(TintColorFlipKey.defaultValue)
		let meanGradientEnd = Color.accentColor

		let meanConfiguration = CKEDataSeriesConfiguration(
			taskID: taskID,
			dataStrategy: dataStrategy,
			mark: .bar,
			legendTitle: String(localized: "AVERAGE"),
			showMarkWhenHighlighted: true,
			showMeanMark: false,
			showMedianMark: false,
			color: meanGradientEnd,
			gradientStartColor: meanGradientStart
		) { event in
			event.computeProgress(by: .maxOutcomeValue())
		}

		let sumConfiguration = CKEDataSeriesConfiguration(
			taskID: taskID,
			dataStrategy: .sum,
			mark: .bar,
			legendTitle: String(localized: "TOTAL"),
			color: Color(TintColorFlipKey.defaultValue)
		) { event in
			event.computeProgress(by: .maxOutcomeValue())
		}

		return [
			meanConfiguration,
			sumConfiguration
		]
	}

	func depressionAndLexaproConfigurations(
		for lexaproTaskID: String
	) -> [CKEDataSeriesConfiguration] {
		let depressionGradientStart = Color(TintColorFlipKey.defaultValue)
		let depressionGradientEnd = Color.accentColor

		let depressionConfiguration = CKEDataSeriesConfiguration(
			taskID: TaskID.depression,
			dataStrategy: .sum,
			mark: .bar,
			legendTitle: String(localized: "DEPRESSION"),
			showMarkWhenHighlighted: true,
			showMeanMark: true,
			showMedianMark: false,
			color: depressionGradientEnd,
			gradientStartColor: depressionGradientStart,
			stackingMethod: .unstacked
		) { event in
			event.computeProgress(by: .summingOutcomeValues())
		}

		let lexaproConfiguration = CKEDataSeriesConfiguration(
			taskID: lexaproTaskID,
			dataStrategy: .sum,
			mark: .bar,
			legendTitle: String(localized: "LEXAPRO"),
			color: .gray,
			gradientStartColor: .gray.opacity(0.3),
			stackingMethod: .unstacked,
			symbol: .diamond,
			interpolation: .catmullRom
		) { event in
			event.computeProgress(by: .averagingOutcomeValues())
		}

		return [
			depressionConfiguration,
			lexaproConfiguration
		]
	}

	var orderedEvents: [CareStoreFetchedResult<OCKAnyEvent>] {
		events.latest.sorted(by: { left, right in
			let leftTaskID = left.result.task.id
			let rightTaskID = right.result.task.id

			return sortedTaskIDs[leftTaskID] ?? 0 < sortedTaskIDs[rightTaskID] ?? 0
		})
	}

	var dateIntervalSegmentView: some View {
		Picker(
			"CHOOSE_DATE_INTERVAL",
			selection: $intervalSelected.animation()
		) {
			Text("TODAY")
				.tag(0)
			Text("WEEK")
				.tag(1)
			Text("MONTH")
				.tag(2)
			Text("YEAR")
				.tag(3)
		}
		#if !os(watchOS)
		.pickerStyle(.segmented)
		#else
		.pickerStyle(.automatic)
		#endif
	}

	var subtitle: String {
		switch intervalSelected {
		case 0:
			return String(localized: "TODAY")
		case 1:
			return String(localized: "WEEK")
		case 2:
			return String(localized: "MONTH")
		case 3:
			return String(localized: "YEAR")
		default:
			return String(localized: "WEEK")
		}
	}

	var eventQueryInterval: DateInterval {
		Calendar.current.dateInterval(
			of: .weekOfYear,
			for: Date()
		)!
	}

	func determineDataStrategy(for taskID: String) -> CKEDataSeriesConfiguration.DataStrategy {
		switch taskID {
		case TaskID.steps:
			return .max
		default:
			return .mean
		}
	}

	func setupChartPropertiesForSegmentSelection(_ segmentValue: Int) {
		let now = Date()
		let calendar = Calendar.current

		switch segmentValue {
		case 0:
			let startOfDay = Calendar.current.startOfDay(for: now)
			let interval = DateInterval(
				start: startOfDay,
				end: now
			)

			period = .day
			chartInterval = interval

		case 1:
			let startDate = calendar.date(
				byAdding: .weekday,
				value: -7,
				to: now
			)!
			period = .week
			chartInterval = DateInterval(start: startDate, end: now)

		case 2:
			let startDate = calendar.date(
				byAdding: .month,
				value: -1,
				to: now
			)!
			period = .month
			chartInterval = DateInterval(start: startDate, end: now)

		case 3:
			let startDate = calendar.date(
				byAdding: .year,
				value: -1,
				to: now
			)!
			period = .month
			chartInterval = DateInterval(start: startDate, end: now)

		default:
			let startDate = calendar.date(
				byAdding: .weekday,
				value: -7,
				to: now
			)!
			period = .week
			chartInterval = DateInterval(start: startDate, end: now)
		}

        events.query.dateInterval = chartInterval
	}

	func computeTaskIDOrder(taskIDs: [String]) -> [String: Int] {
		taskIDs.enumerated().reduce(into: [String: Int]()) { taskDictionary, task in
			taskDictionary[task.element] = task.offset
		}
	}

	static func query() -> OCKEventQuery {
		OCKEventQuery(dateInterval: .init())
	}
}

#Preview {
	InsightsView()
		.environment(\.careStore, Utility.createPreviewStore())
		.careKitStyle(Styler())
}
