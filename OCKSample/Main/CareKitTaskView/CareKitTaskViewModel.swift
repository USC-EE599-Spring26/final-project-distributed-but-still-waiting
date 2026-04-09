//
//  CareKitTaskViewModel.swift
//  OCKSample
//
//  Created by Jai Shah on 28/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import os.log

@MainActor
class CareKitTaskViewModel: ObservableObject {

    @Published var error: AppError?
    @Published var selectedCarePlanUUID: UUID?
    @Published var availableCarePlans: [OCKCarePlan] = []

    // MARK: Intents
    func addTask(
        _ title: String,
        instructions: String,
        cardType: CareKitCard,
        priority: Int,
        asset: String
    ) async {
        guard let appDelegate = AppDelegateKey.defaultValue else {
            error = AppError.couldntBeUnwrapped
            return
        }
        let uniqueId = UUID().uuidString // Create a unique id for each task
        var task = OCKTask(id: uniqueId,
                           title: title,
                           carePlanUUID: selectedCarePlanUUID,
                           schedule: .dailyAtTime(hour: 0,
                                                  minutes: 0,
                                                  start: Date(),
                                                  end: nil,
                                                  text: nil))
        task.instructions = instructions
        task.card = cardType
        task.priority = priority
        // store SF Symbol asset on the task so views can show it
        task.asset = asset
        do {
            _ = try await appDelegate.store.addTasksIfNotPresent([task])
            Logger.careKitTask.info("Saved task: \(task.id, privacy: .private)")
            // Notify views they should refresh tasks if needed
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.shouldRefreshView)))
        } catch {
            self.error = AppError.errorString("Could not add task: \(error.localizedDescription)")
        }
    }

    func addHealthKitTask(
        _ title: String,
        instructions: String,
        cardType: CareKitCard,
        priority: Int,
        asset: String
    ) async {
        guard let appDelegate = AppDelegateKey.defaultValue else {
            error = AppError.couldntBeUnwrapped
            return
        }
        let uniqueId = UUID().uuidString // Create a unique id for each task
        var healthKitTask = OCKHealthKitTask(id: uniqueId,
                                             title: title,
                                             carePlanUUID: selectedCarePlanUUID,
                                             schedule: .dailyAtTime(hour: 0,
                                                                    minutes: 0,
                                                                    start: Date(),
                                                                    end: nil,
                                                                    text: nil),
                                             healthKitLinkage: .init(quantityIdentifier: .electrodermalActivity,
                                                                     quantityType: .discrete,
                                                                     unit: .count()))
        healthKitTask.instructions = instructions
        healthKitTask.card = cardType
        healthKitTask.priority = priority
        // store SF Symbol asset on the health kit task for UI
        healthKitTask.asset = asset
        do {
            _ = try await appDelegate.healthKitStore.addTasksIfNotPresent([healthKitTask])
            Logger.careKitTask.info("Saved HealthKitTask: \(healthKitTask.id, privacy: .private)")
            // Notify views they should refresh tasks if needed
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.shouldRefreshView)))
            // Ask HealthKit store for permissions after each new task
            #if os(iOS) || os(visionOS)
            Utility.requestHealthKitPermissions()
            #endif
        } catch {
            self.error = AppError.errorString("Could not add task: \(error.localizedDescription)")
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
}
