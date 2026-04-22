//
//  ManageTasksViewModel.swift
//  OCKSample
//
//  Created by Jai Shah on 06/03/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import os.log

@MainActor
final class ManageTasksViewModel: ObservableObject {

    @Published var tasks: [OCKAnyTask] = []
    @Published var orderedTasks: [OCKAnyTask] = []
    @Published var carePlanTitlesByUUID: [UUID: String] = [:]
    @Published var error: AppError?

    private let store: any OCKAnyTaskStore

    init(store: OCKAnyTaskStore) {
        self.store = store
    }

    func carePlanTitle(for task: OCKAnyTask) -> String {
        guard let carePlanUUID = carePlanUUID(for: task) else {
            return "No Care Plan"
        }
        return carePlanTitlesByUUID[carePlanUUID] ?? "Unknown Care Plan"
    }

    // MARK: Fetch Care Plans
    func fetchCarePlans(store: OCKAnyStoreProtocol) async {
        do {
            let carePlans = try await store.fetchAnyCarePlans(query: OCKCarePlanQuery())
            let concreteCarePlans = carePlans.compactMap { $0 as? OCKCarePlan }
            carePlanTitlesByUUID = concreteCarePlans.reduce(into: [:]) { titlesByUUID, carePlan in
                titlesByUUID[carePlan.uuid] = carePlan.title
            }
        } catch {
            Logger.careKitTask.error("Could not fetch care plans: \(error.localizedDescription, privacy: .public)")
            self.error = AppError.errorString(
                "Could not fetch care plans: \(error.localizedDescription)"
            )
        }
    }

    // MARK: Fetch Tasks
    func fetchTasks() async {

        var query = OCKTaskQuery(for: Date())
        query.excludesTasksWithNoEvents = true

        do {
            let fetchedTasks = try await store.fetchAnyTasks(query: query)
            let managementTasks = fetchedTasks.filter { $0.id != Onboard.identifier() }

            tasks = managementTasks.sorted { firstTask, secondTask in
                let firstPriority = (firstTask as? CareTask)?.priority ?? Int.max
                let secondPriority = (secondTask as? CareTask)?.priority ?? Int.max
                return firstPriority < secondPriority
            }
            Logger.careKitTask.info("Fetched \(self.tasks.count, privacy: .public) tasks for management")
        } catch {
            Logger.careKitTask.error("Could not fetch tasks: \(error.localizedDescription, privacy: .public)")
            self.error = AppError.errorString(
                "Could not fetch tasks: \(error.localizedDescription)"
            )
        }
    }

    // MARK: Delete Task
    func deleteTasks(at offsets: IndexSet) async {

        let deletedTasks = offsets.map { tasks[$0] }

        // Remove locally so UI updates immediately
        tasks.remove(atOffsets: offsets)

        for task in deletedTasks {
            do {
                try await store.deleteAnyTask(task)
                Logger.careKitTask.info("Deleted task: \(task.id, privacy: .private)")
            } catch {
                Logger.careKitTask.error("Could not delete task: \(error.localizedDescription, privacy: .public)")
                self.error = AppError.errorString(
                    "Could not delete task: \(error.localizedDescription)"
                )
            }
        }

        // Optional refresh for safety
        await fetchTasks()

        NotificationCenter.default.post(
            .init(name: Notification.Name(rawValue: Constants.shouldRefreshView))
        )
    }

    private func carePlanUUID(for task: OCKAnyTask) -> UUID? {
        if let standardTask = task as? OCKTask {
            return standardTask.carePlanUUID
        }
        if let healthTask = task as? OCKHealthKitTask {
            return healthTask.carePlanUUID
        }
        return nil
    }
}
