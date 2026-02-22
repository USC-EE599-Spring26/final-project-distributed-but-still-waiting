//
//  TimelineViewModel.swift
//  OCKSample
//
//  Created by Jai Shah on 21/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//


import Foundation
import CareKit
import CareKitStore

@MainActor
final class TimelineViewModel: ObservableObject {

    // MARK: - Nested Model (Feature Scoped)
    struct Item: Identifiable {
        let id: String
        let title: String
        let date: Date
        let outcomeText: String
        let numericValue: Double
        let normalizedValue: Double   // 0 → 1

    }

    // MARK: - Published State
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading: Bool = false

    private var store: OCKAnyStoreProtocol?

    // MARK: - Inject Store
    func configure(with store: OCKAnyStoreProtocol) {
        self.store = store
    }

    // MARK: - Load Timeline
    func loadTimeline() async {
        guard let store else { return }

        isLoading = true

        do {
            let startDate = Calendar.current.date(byAdding: .year, value: -5, to: Date())!
            let interval = DateInterval(start: startDate, end: Date())
            let query = OCKEventQuery(dateInterval: interval)

            let anyEventStore = store as OCKAnyEventStore
            let events = try await anyEventStore.fetchAnyEvents(query: query)

            let rawItems = events.compactMap(makeItem)

            // Find dataset max (avoid divide-by-zero)
            let maxValue = rawItems.map(\.numericValue).max() ?? 1

            // Create final normalized items
            let normalizedItems = rawItems.map { item in
                Item(
                    id: item.id,
                    title: item.title,
                    date: item.date,
                    outcomeText: item.outcomeText,
                    numericValue: item.numericValue,
                    normalizedValue: item.numericValue / maxValue
                )
            }
            .sorted { $0.date > $1.date }

            self.items = normalizedItems
            for item in self.items {
                print(item.date)
            }
            
            

        } catch {
            print("Timeline fetch failed:", error)
            self.items = []
        }

        isLoading = false
    }
}

// MARK: - Mapping Helpers
private extension TimelineViewModel {

    func makeItem(from event: OCKAnyEvent) -> Item? {

        // Ignore scheduled but unperformed events
        guard let outcome = event.outcome,
              outcome.values.isEmpty == false else {
            return nil
        }

        let uniqueID = "\(event.task.uuid.uuidString)-\(event.scheduleEvent.occurrence)"
        let numeric = extractPrimaryValue(outcome.values)

        return Item(
            id: uniqueID,
            title: event.task.title ?? "Workout",
            date: event.scheduleEvent.start,
            outcomeText: formatOutcome(outcome.values),
            numericValue: numeric,
            normalizedValue: 0
        )
    }
    
    func extractPrimaryValue(_ values: [OCKOutcomeValue]) -> Double {
        for v in values {
            if let int = v.integerValue { return Double(int) }
            if let double = v.doubleValue { return double }
        }
        return 0
    }

    func formatOutcome(_ values: [OCKOutcomeValue]) -> String {
        var parts: [String] = []

        for value in values {

            if let int = value.integerValue {
                if value.units?.localizedCaseInsensitiveContains("step") == true {
                    parts.append("\(int) steps")
                } else {
                    parts.append("\(int) \(value.units ?? "")")
                }
            }

            if let double = value.doubleValue {
                if value.units?.localizedCaseInsensitiveContains("kcal") == true ||
                   value.units?.localizedCaseInsensitiveContains("cal") == true {
                    parts.append("\(Int(double)) kcal")
                } else {
                    parts.append("\(Int(double)) \(value.units ?? "")")
                }
            }

            if let string = value.stringValue {
                parts.append(string)
            }
        }

        return parts.joined(separator: " • ")
    }
}
