//
//  CareKitTaskViewModel.swift
//  OCKSample
//
//  Created by Jai Shah on 28/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import HealthKit
import os.log

// ADDED
enum TaskCardType: String, CaseIterable, Identifiable {
    var id: Self { self }

    case button = "Button"
    case checklist = "Checklist"
    case instruction = "Instruction"
    case simple = "Simple"
    case healthKitNumeric = "HealthKit Numeric Progress"

    var card: CareKitCard {
        switch self {
        case .button:
            return .button
        case .checklist:
            return .checklist
        case .instruction:
            return .instruction
        case .simple:
            return .simple
        case .healthKitNumeric:
            return CareKitCard.numericProgress
        }
    }

}

// ADDED
enum HealthKitQuantityOption: String, CaseIterable, Identifiable {
    var id: Self { self }

    case stepCount = "Step Count"
    case heartRate = "Heart Rate"
    case activeEnergyBurned = "Active Energy Burned"
    case distanceWalkingRunning = "Walking + Running Distance"
    case bodyMass = "Body Mass"
    case electrodermalActivity = "Electrodermal Activity"

    var identifier: HKQuantityTypeIdentifier {
        switch self {
        case .stepCount:
            return .stepCount
        case .heartRate:
            return .heartRate
        case .activeEnergyBurned:
            return .activeEnergyBurned
        case .distanceWalkingRunning:
            return .distanceWalkingRunning
        case .bodyMass:
            return .bodyMass
        case .electrodermalActivity:
            return .electrodermalActivity
        }
    }

    var defaultUnit: HealthKitUnitOption {
        switch self {
        case .stepCount:
            return .count
        case .heartRate:
            return .countPerMinute
        case .activeEnergyBurned:
            return .kilocalorie
        case .distanceWalkingRunning:
            return .meter
        case .bodyMass:
            return .kilogram
        case .electrodermalActivity:
            return .siemens
        }
    }

    var defaultAggregation: HealthKitAggregationOption {
        switch self {
        case .stepCount, .activeEnergyBurned, .distanceWalkingRunning:
            return .sum
        case .heartRate, .bodyMass, .electrodermalActivity:
            return .average
        }
    }
}

// ADDED
enum HealthKitUnitOption: String, CaseIterable, Identifiable {
    var id: Self { self }

    case count = "count"
    case countPerMinute = "count/min"
    case kilocalorie = "kcal"
    case meter = "m"
    case kilogram = "kg"
    case siemens = "S"

    var unit: HKUnit {
        switch self {
        case .count:
            return .count()
        case .countPerMinute:
            return .count().unitDivided(by: .minute())
        case .kilocalorie:
            return .kilocalorie()
        case .meter:
            return .meter()
        case .kilogram:
            return .gramUnit(with: .kilo)
        case .siemens:
            return .siemen()
        }
    }
}

// ADDED
enum HealthKitAggregationOption: String, CaseIterable, Identifiable {
    var id: Self { self }

    case sum = "Sum"
    case average = "Average"

    var quantityType: OCKHealthKitLinkage.QuantityType {
        switch self {
        case .sum:
            return .cumulative
        case .average:
            return .discrete
        }
    }
}

@MainActor
class NewTaskViewModel: ObservableObject {

    @Published var error: AppError?
    @Published var selectedCarePlanUUID: UUID?
    @Published var availableCarePlans: [OCKCarePlan] = []
    @Published var title = ""
    @Published var instructions = ""
    @Published var selectedCardType: TaskCardType = .button {
        didSet {
            resetIrrelevantFields()
        }
    }
    @Published var priority = 100
    @Published var asset = "pills.fill"
    @Published var scheduleDate = Date()
    @Published var checklistItems: [String] = [""]
    @Published var healthKitQuantity: HealthKitQuantityOption = .stepCount {
        didSet {
            healthKitUnit = healthKitQuantity.defaultUnit
            healthKitAggregation = healthKitQuantity.defaultAggregation
        }
    }
    @Published var healthKitUnit: HealthKitUnitOption = .count
    @Published var healthKitAggregation: HealthKitAggregationOption = .sum

    var canAddTask: Bool {
        switch selectedCardType {
        case .checklist:
            return !resolvedTitle.isEmpty && !cleanedChecklistItems.isEmpty
        case .healthKitNumeric:
            return !resolvedTitle.isEmpty
        case .button, .instruction, .simple:
            return !resolvedTitle.isEmpty
        }
    }

    // MARK: Intents
    // MODIFIED
    func addTask() async -> Bool {
        error = nil
        if selectedCardType == .healthKitNumeric {
            return await addHealthKitTask()
        }
        return await addStandardTask()
    }

    // MARK: Task Creation
    private func addStandardTask() async -> Bool {
        guard let appDelegate = AppDelegateKey.defaultValue else {
            error = AppError.couldntBeUnwrapped
            return false
        }
        guard canAddTask else {
            error = AppError.errorString("Please complete the required task fields.")
            return false
        }

        let uniqueId = UUID().uuidString
        var task = OCKTask(
            id: uniqueId,
            title: resolvedTitle,
            carePlanUUID: selectedCarePlanUUID,
            schedule: makeSchedule(for: selectedCardType)
        )
        task.instructions = cleanedInstructions
        task.card = selectedCardType.card
        task.priority = priority
        task.asset = asset
        task.impactsAdherence = true

        do {
            _ = try await appDelegate.store.addTasksIfNotPresent([task])
            Logger.careKitTask.info("Saved task: \(task.id, privacy: .private)")
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.shouldRefreshView)))
            return true
        } catch {
            self.error = AppError.errorString("Could not add task: \(error.localizedDescription)")
            return false
        }
    }

    private func addHealthKitTask() async -> Bool {
        guard let appDelegate = AppDelegateKey.defaultValue else {
            error = AppError.couldntBeUnwrapped
            return false
        }
        guard canAddTask else {
            error = AppError.errorString("Please complete the required HealthKit task fields.")
            return false
        }

        let uniqueId = UUID().uuidString
        var healthKitTask = OCKHealthKitTask(
            id: uniqueId,
            title: resolvedTitle,
            carePlanUUID: selectedCarePlanUUID,
            schedule: makeDailySchedule(text: nil),
            healthKitLinkage: .init(
                quantityIdentifier: healthKitQuantity.identifier,
                quantityType: healthKitAggregation.quantityType,
                unit: healthKitUnit.unit
            )
        )
        healthKitTask.instructions = cleanedInstructions
        healthKitTask.card = CareKitCard.numericProgress
        healthKitTask.priority = priority
        healthKitTask.asset = asset
        healthKitTask.impactsAdherence = true

        do {
            _ = try await appDelegate.healthKitStore.addTasksIfNotPresent([healthKitTask])
            Logger.careKitTask.info("Saved HealthKitTask: \(healthKitTask.id, privacy: .private)")
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.shouldRefreshView)))
            #if os(iOS) || os(visionOS)
            Utility.requestHealthKitPermissions()
            #endif
            return true
        } catch {
            self.error = AppError.errorString("Could not add task: \(error.localizedDescription)")
            return false
        }
    }

    func loadCarePlans(store: OCKAnyStoreProtocol) async {
        do {
            let plans = try await store.fetchAnyCarePlans(query: OCKCarePlanQuery())

            await MainActor.run {
                self.availableCarePlans = plans.compactMap { $0 as? OCKCarePlan }

                // Optional default selection
                if self.selectedCarePlanUUID == nil {
                    self.selectedCarePlanUUID = self.availableCarePlans.first?.uuid
                }
            }
        } catch {
            Logger.appDelegate.error("Failed to load care plans")
        }
    }

    func addChecklistItem() {
        checklistItems.append("")
    }

    func removeChecklistItems(at offsets: IndexSet) {
        checklistItems.remove(atOffsets: offsets)
        if checklistItems.isEmpty {
            checklistItems = [""]
        }
    }

    private var cleanedInstructions: String {
        instructions.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanedChecklistItems: [String] {
        checklistItems
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var resolvedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resetIrrelevantFields() {
        if selectedCardType == .healthKitNumeric {
            instructions = ""
        }

        if selectedCardType != .healthKitNumeric {
            healthKitQuantity = .stepCount
        }

        switch selectedCardType {
        case .checklist:
            break
        case .healthKitNumeric:
            checklistItems = [""]
        case .button, .instruction, .simple:
            checklistItems = [""]
        }
    }

    private func makeSchedule(for cardType: TaskCardType) -> OCKSchedule {
        if cardType == .checklist {
            return makeChecklistSchedule()
        }
        return makeDailySchedule(text: nil)
    }

    private func makeChecklistSchedule() -> OCKSchedule {
        let items = cleanedChecklistItems
        guard !items.isEmpty else {
            return makeDailySchedule(text: nil)
        }

        let elements = items.map { item in
            OCKScheduleElement(
                start: scheduleDate,
                end: nil,
                interval: DateComponents(day: 1),
                text: item,
                targetValues: [],
                duration: .allDay
            )
        }
        return OCKSchedule(composing: elements)
    }

    private func makeDailySchedule(text: String?) -> OCKSchedule {
        let components = Calendar.current.dateComponents([.hour, .minute], from: scheduleDate)
        return .dailyAtTime(
            hour: components.hour ?? 0,
            minutes: components.minute ?? 0,
            start: scheduleDate,
            end: nil,
            text: text,
            duration: .allDay
        )
    }

}

// MODIFIED
typealias CareKitTaskViewModel = NewTaskViewModel
