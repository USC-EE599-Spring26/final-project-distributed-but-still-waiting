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
enum TaskCardType: CaseIterable, Identifiable {
    var id: Self { self }

    case button
    case checklist
    case instruction
    case simple
    case healthKitNumeric

    var displayTitle: String {
        switch self {
        case .button:
            return String(localized: "TASK_CARD_BUTTON")
        case .checklist:
            return String(localized: "TASK_CARD_CHECKLIST")
        case .instruction:
            return String(localized: "TASK_CARD_INSTRUCTION")
        case .simple:
            return String(localized: "TASK_CARD_SIMPLE")
        case .healthKitNumeric:
            return String(localized: "TASK_CARD_HEALTHKIT_NUMERIC")
        }
    }

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

    var defaultAsset: String {
        switch self {
        case .button:
            return "checkmark.circle.fill"
        case .checklist:
            return "checklist"
        case .instruction:
            return "book.closed.fill"
        case .simple:
            return "square.grid.2x2.fill"
        case .healthKitNumeric:
            return "heart.fill"
        }
    }

    var defaultInstructions: String {
        switch self {
        case .button:
            return String(localized: "TASK_INSTRUCTIONS_BUTTON")
        case .checklist:
            return String(localized: "TASK_INSTRUCTIONS_CHECKLIST")
        case .instruction:
            return String(localized: "TASK_INSTRUCTIONS_INSTRUCTION")
        case .simple:
            return String(localized: "TASK_INSTRUCTIONS_SIMPLE")
        case .healthKitNumeric:
            return String(localized: "TASK_INSTRUCTIONS_HEALTHKIT_NUMERIC")
        }
    }

}

// ADDED
enum HealthKitQuantityOption: CaseIterable, Identifiable {
    var id: Self { self }

    case stepCount
    case heartRate
    case activeEnergyBurned
    case distanceWalkingRunning
    case bodyMass
    case electrodermalActivity

    var displayTitle: String {
        switch self {
        case .stepCount:
            return String(localized: "HEALTHKIT_QUANTITY_STEP_COUNT")
        case .heartRate:
            return String(localized: "HEALTHKIT_QUANTITY_HEART_RATE")
        case .activeEnergyBurned:
            return String(localized: "HEALTHKIT_QUANTITY_ACTIVE_ENERGY_BURNED")
        case .distanceWalkingRunning:
            return String(localized: "HEALTHKIT_QUANTITY_DISTANCE_WALKING_RUNNING")
        case .bodyMass:
            return String(localized: "HEALTHKIT_QUANTITY_BODY_MASS")
        case .electrodermalActivity:
            return String(localized: "HEALTHKIT_QUANTITY_ELECTRODERMAL_ACTIVITY")
        }
    }

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

    var defaultAsset: String {
        switch self {
        case .stepCount:
            return "figure.walk"
        case .heartRate:
            return "heart.fill"
        case .activeEnergyBurned:
            return "flame.fill"
        case .distanceWalkingRunning:
            return "figure.walk.motion"
        case .bodyMass:
            return "scalemass.fill"
        case .electrodermalActivity:
            return "waveform.path.ecg"
        }
    }

    var defaultInstructions: String {
        switch self {
        case .stepCount:
            return String(localized: "HEALTHKIT_INSTRUCTIONS_STEP_COUNT")
        case .heartRate:
            return String(localized: "HEALTHKIT_INSTRUCTIONS_HEART_RATE")
        case .activeEnergyBurned:
            return String(localized: "HEALTHKIT_INSTRUCTIONS_ACTIVE_ENERGY_BURNED")
        case .distanceWalkingRunning:
            return String(localized: "HEALTHKIT_INSTRUCTIONS_DISTANCE_WALKING_RUNNING")
        case .bodyMass:
            return String(localized: "HEALTHKIT_INSTRUCTIONS_BODY_MASS")
        case .electrodermalActivity:
            return String(localized: "HEALTHKIT_INSTRUCTIONS_ELECTRODERMAL_ACTIVITY")
        }
    }
}

// ADDED
enum HealthKitUnitOption: CaseIterable, Identifiable {
    var id: Self { self }

    case count
    case countPerMinute
    case kilocalorie
    case meter
    case kilogram
    case siemens

    var displayTitle: String {
        switch self {
        case .count:
            return String(localized: "HEALTHKIT_UNIT_COUNT")
        case .countPerMinute:
            return String(localized: "HEALTHKIT_UNIT_COUNT_PER_MINUTE")
        case .kilocalorie:
            return String(localized: "HEALTHKIT_UNIT_KILOCALORIE")
        case .meter:
            return String(localized: "HEALTHKIT_UNIT_METER")
        case .kilogram:
            return String(localized: "HEALTHKIT_UNIT_KILOGRAM")
        case .siemens:
            return String(localized: "HEALTHKIT_UNIT_SIEMENS")
        }
    }

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
enum HealthKitAggregationOption: CaseIterable, Identifiable {
    var id: Self { self }

    case sum
    case average

    var displayTitle: String {
        switch self {
        case .sum:
            return String(localized: "HEALTHKIT_AGGREGATION_SUM")
        case .average:
            return String(localized: "HEALTHKIT_AGGREGATION_AVERAGE")
        }
    }

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
    @Published var instructions = TaskCardType.button.defaultInstructions
    @Published var selectedCardType: TaskCardType = .button {
        didSet {
            resetIrrelevantFields()
        }
    }
    @Published var priority = 25
    @Published var asset = TaskCardType.button.defaultAsset
    @Published var scheduleDate = Date()
    @Published var checklistItems: [String] = [""]
    @Published var healthKitQuantity: HealthKitQuantityOption = .stepCount {
        didSet {
            healthKitUnit = healthKitQuantity.defaultUnit
            healthKitAggregation = healthKitQuantity.defaultAggregation
            if selectedCardType == .healthKitNumeric {
                asset = healthKitQuantity.defaultAsset
                instructions = healthKitQuantity.defaultInstructions
            }
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
            error = AppError.errorString(String(localized: "ERROR_COMPLETE_REQUIRED_TASK_FIELDS"))
            return false
        }

        let uniqueId = UUID().uuidString
        var task = OCKTask(
            id: uniqueId,
            title: resolvedTitle,
            carePlanUUID: selectedCarePlanUUID,
            schedule: makeSchedule(for: selectedCardType)
        )
        task.instructions = resolvedInstructions
        task.card = selectedCardType.card
        task.priority = priority
        task.asset = resolvedAsset
        task.impactsAdherence = true

        do {
            _ = try await appDelegate.store.addTasksIfNotPresent([task])
            Logger.careKitTask.info("Saved task: \(task.id, privacy: .private)")
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.shouldRefreshView)))
            return true
        } catch {
            self.error = AppError.errorString(
                String(
                    format: String(localized: "ERROR_COULD_NOT_ADD_TASK"),
                    error.localizedDescription
                )
            )
            return false
        }
    }

    private func addHealthKitTask() async -> Bool {
        guard let appDelegate = AppDelegateKey.defaultValue else {
            error = AppError.couldntBeUnwrapped
            return false
        }
        guard canAddTask else {
            error = AppError.errorString(String(localized: "ERROR_COMPLETE_REQUIRED_HEALTHKIT_FIELDS"))
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
        healthKitTask.instructions = resolvedInstructions
        healthKitTask.card = CareKitCard.numericProgress
        healthKitTask.priority = priority
        healthKitTask.asset = resolvedAsset
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
            self.error = AppError.errorString(
                String(
                    format: String(localized: "ERROR_COULD_NOT_ADD_TASK"),
                    error.localizedDescription
                )
            )
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

    private var resolvedInstructions: String {
        if !cleanedInstructions.isEmpty {
            return cleanedInstructions
        }
        if selectedCardType == .healthKitNumeric {
            return healthKitQuantity.defaultInstructions
        }
        return selectedCardType.defaultInstructions
    }

    private var cleanedChecklistItems: [String] {
        checklistItems
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var resolvedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var resolvedAsset: String {
        let cleanedAsset = asset.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedAsset.isEmpty {
            return cleanedAsset
        }
        if selectedCardType == .healthKitNumeric {
            return healthKitQuantity.defaultAsset
        }
        return selectedCardType.defaultAsset
    }

    private func resetIrrelevantFields() {
        if selectedCardType == .healthKitNumeric {
            instructions = healthKitQuantity.defaultInstructions
            asset = healthKitQuantity.defaultAsset
        }

        if selectedCardType != .healthKitNumeric {
            healthKitQuantity = .stepCount
            instructions = selectedCardType.defaultInstructions
            asset = selectedCardType.defaultAsset
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
