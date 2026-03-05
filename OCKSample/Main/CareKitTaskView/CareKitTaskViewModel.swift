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

	// MARK: Intents
    func addTask(
        _ title: String,
        instructions: String,
        cardType: CareKitCard,
        priority: Int
	) async {
		guard let appDelegate = AppDelegateKey.defaultValue else {
			error = AppError.couldntBeUnwrapped
			return
		}
		let uniqueId = UUID().uuidString // Create a unique id for each task
		var task = OCKTask(id: uniqueId,
						   title: title,
						   carePlanUUID: nil,
						   schedule: .dailyAtTime(hour: 0,
												  minutes: 0,
												  start: Date(),
												  end: nil,
												  text: nil))
		task.instructions = instructions
		task.card = cardType
        task.priority = priority
		do {
			_ = try await appDelegate.store.addTasksIfNotPresent([task])
			Logger.careKitTask.info("Saved task: \(task.id, privacy: .private)")
			// Notify views they should refresh tasks if needed
			NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.shouldRefreshView)))
		} catch {
			self.error = AppError.errorString("Could not add task: \(error.localizedDescription)")
		}
	}
    @Published var tasks: [OCKAnyTask] = []

    func fetchTasks() async {
        guard let appDelegate = AppDelegateKey.defaultValue else { return }
        // this might be converted to var in future for better UX
        let query = OCKTaskQuery()

        do {
            tasks = try await appDelegate.store.fetchAnyTasks(query: query)
        } catch {
            self.error = AppError.errorString("Could not fetch tasks: \(error.localizedDescription)")
        }
    }

    func deleteTask(task: OCKAnyTask) async {
        guard let appDelegate = AppDelegateKey.defaultValue else { return }

        do {
            try await appDelegate.store.deleteAnyTask(task)

            // Refresh the list from CareKit
            await fetchTasks()

            NotificationCenter.default.post(
                .init(name: Notification.Name(rawValue: Constants.shouldRefreshView))
            )

        } catch {
            self.error = AppError.errorString(
                "Could not delete task: \(error.localizedDescription)"
            )
        }
    }

    func addHealthKitTask(
        _ title: String,
        instructions: String,
        cardType: CareKitCard,
        priority: Int
    ) async {
		guard let appDelegate = AppDelegateKey.defaultValue else {
			error = AppError.couldntBeUnwrapped
			return
		}
		let uniqueId = UUID().uuidString // Create a unique id for each task
		var healthKitTask = OCKHealthKitTask(id: uniqueId,
											 title: title,
											 carePlanUUID: nil,
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
}
