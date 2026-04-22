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
    @Published var error: AppError?

    private let store: any OCKAnyTaskStore

    init(store: OCKAnyTaskStore) {
        self.store = store
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
}
