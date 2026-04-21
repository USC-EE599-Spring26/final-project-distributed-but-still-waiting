//
//  InsightsCustomCardView.swift
//  OCKSample
//
//  Created by Jai Shah on 4/21/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUI
import Charts
import Foundation
import SwiftUI

struct InsightsCustomCardView: View {
	@Environment(\.customStyler) private var style
	@Environment(\.isCardEnabled) private var isCardEnabled
	@CareStoreFetchRequest(query: query()) private var events

	let title: String
	let subtitle: String
	let intervalSelected: Int
	let taskIDs: [String]
	@Binding var dateInterval: DateInterval

	init(
		title: String = "Outcome Trends",
		subtitle: String,
		intervalSelected: Int,
		dateInterval: Binding<DateInterval>,
		taskIDs: [String] = Self.defaultTaskIDs
	) {
		self.title = title
		self.subtitle = subtitle
		self.intervalSelected = intervalSelected
		self.taskIDs = taskIDs
		_dateInterval = dateInterval
	}

	var body: some View {
		CardView {
			VStack(alignment: .leading, spacing: 16) {
				headerView

				if chartPoints.isEmpty {
					emptyStateView
				} else {
					chartView
				}
			}
			.padding(isCardEnabled ? [.all] : [])
		}
		.careKitStyle(style)
		.onAppear {
			updateQuery()
		}
		.onChange(of: dateInterval) {
			updateQuery()
		}
	}

	private var headerView: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(title)
				.font(.headline)
				.foregroundStyle(.primary)

			Text(subtitle)
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
	}

	private var chartView: some View {
		Chart(chartPoints) { point in
			LineMark(
				x: .value("Date", point.date, unit: timeline.dateUnit),
				y: .value("Average Outcome", point.value)
			)
			.foregroundStyle(by: .value("Task", point.taskTitle))
			.interpolationMethod(.catmullRom)

			PointMark(
				x: .value("Date", point.date, unit: timeline.dateUnit),
				y: .value("Average Outcome", point.value)
			)
			.foregroundStyle(by: .value("Task", point.taskTitle))
			.symbol(by: .value("Task", point.taskTitle))
			.symbolSize(44)
		}
		.chartYScale(domain: yAxisDomain)
		.chartXAxis {
			AxisMarks(values: .automatic(desiredCount: timeline.desiredAxisMarkCount))
		}
		.chartYAxis {
			AxisMarks(position: .leading)
		}
		.chartLegend(position: .bottom, alignment: .leading)
		.frame(height: 220)
		.accessibilityLabel(Text("Outcome trends chart"))
	}

	private var emptyStateView: some View {
		VStack(spacing: 8) {
			Image(systemName: "chart.xyaxis.line")
				.font(.title2)
				.foregroundStyle(Color.accentColor)
			Text("No outcomes recorded")
				.font(.subheadline.weight(.semibold))
			Text("Complete tasks to see this chart update.")
				.font(.footnote)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
		}
		.frame(maxWidth: .infinity, minHeight: 220)
	}

	private var chartPoints: [OutcomeChartPoint] {
		let rawPoints = events.latest
			.flatMap { rawOutcomePoints(for: $0.result) }

		let buckets = rawPoints.reduce(into: [OutcomeChartBucket: [Double]]()) { result, rawPoint in
			let bucketDate = bucketStartDate(for: rawPoint.date)
			let bucket = OutcomeChartBucket(
				date: bucketDate,
				taskID: rawPoint.taskID,
				taskTitle: rawPoint.taskTitle
			)
			result[bucket, default: []].append(rawPoint.value)
		}

		return buckets
			.map { bucket, values in
				let average = values.reduce(0, +) / Double(values.count)
				return OutcomeChartPoint(
					date: bucket.date,
					taskID: bucket.taskID,
					taskTitle: bucket.taskTitle,
					value: average
				)
			}
			.sorted {
				if $0.taskTitle == $1.taskTitle {
					return $0.date < $1.date
				}
				return $0.taskTitle < $1.taskTitle
			}
	}

	private var yAxisDomain: ClosedRange<Double> {
		let maxValue = chartPoints.map(\.value).max() ?? 1
		guard maxValue > 1 else {
			return 0...1
		}
		return 0...(maxValue * 1.1)
	}

	private var timeline: InsightsChartTimeline {
		InsightsChartTimeline(selection: intervalSelected)
	}

	private func rawOutcomePoints(for event: OCKAnyEvent) -> [RawOutcomePoint] {
		guard let outcome = event.outcome else {
			return []
		}

		return outcome.values.compactMap { value in
			guard let numericValue = Self.numericValue(from: value) else {
				return nil
			}

			let date = value.createdDate
			guard date >= dateInterval.start && date <= dateInterval.end else {
				return nil
			}

			return RawOutcomePoint(
				date: date,
				taskID: event.task.id,
				taskTitle: event.title,
				value: numericValue
			)
		}
	}

	private func bucketStartDate(for date: Date) -> Date {
		Calendar.current.dateInterval(
			of: timeline.bucketComponent,
			for: date
		)?.start ?? date
	}

	private func updateQuery() {
		if events.query.taskIDs != taskIDs {
			events.query.taskIDs = taskIDs
		}

		if events.query.dateInterval != dateInterval {
			events.query.dateInterval = dateInterval
		}
	}

	private static func numericValue(from value: OCKOutcomeValue) -> Double? {
		if let doubleValue = value.doubleValue {
			return doubleValue
		}

		if let integerValue = value.integerValue {
			return Double(integerValue)
		}

		if let booleanValue = value.booleanValue {
			return booleanValue ? 1 : 0
		}

		return nil
	}

	private static var defaultTaskIDs: [String] {
		[
			TaskID.energy,
			TaskID.depression,
			TaskID.lexapro,
			TaskID.cbtExercises
		]
	}

	static func query() -> OCKEventQuery {
		var query = OCKEventQuery(dateInterval: .init())
		query.taskIDs = defaultTaskIDs
		return query
	}
}

private struct RawOutcomePoint {
	let date: Date
	let taskID: String
	let taskTitle: String
	let value: Double
}

private struct OutcomeChartBucket: Hashable {
	let date: Date
	let taskID: String
	let taskTitle: String
}

private struct OutcomeChartPoint: Identifiable {
	let date: Date
	let taskID: String
	let taskTitle: String
	let value: Double

	var id: String {
		"\(taskID)-\(date.timeIntervalSince1970)"
	}
}

private enum InsightsChartTimeline {
	case today
	case week
	case month
	case year

	init(selection: Int) {
		switch selection {
		case 0:
			self = .today
		case 1:
			self = .week
		case 2:
			self = .month
		case 3:
			self = .year
		default:
			self = .week
		}
	}

	var bucketComponent: Calendar.Component {
		switch self {
		case .today:
			return .hour
		case .week, .month:
			return .day
		case .year:
			return .month
		}
	}

	var dateUnit: Calendar.Component {
		switch self {
		case .today:
			return .hour
		case .week, .month:
			return .day
		case .year:
			return .month
		}
	}

	var desiredAxisMarkCount: Int {
		switch self {
		case .today:
			return 6
		case .week:
			return 7
		case .month:
			return 5
		case .year:
			return 6
		}
	}
}

struct InsightsCustomCardView_Previews: PreviewProvider {
	static var previews: some View {
		InsightsCustomCardViewPreview()
	}
}

private struct InsightsCustomCardViewPreview: View {
	@State private var dateInterval = DateInterval(
		start: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
		end: Date()
	)

	var body: some View {
		InsightsCustomCardView(
			subtitle: "WEEK",
			intervalSelected: 1,
			dateInterval: $dateInterval
		)
		.environment(\.careStore, Utility.createPreviewStore())
		.careKitStyle(Styler())
		.padding()
	}
}
