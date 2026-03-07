//
//  ManageTasksViewModel.swift
//  OCKSample
//
//  Created by Jai Shah on 06/03/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore

@MainActor
final class ManageTasksViewModel: ObservableObject {

    @Published var tasks: [OCKAnyTask] = []
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
            tasks = try await store.fetchAnyTasks(query: query)
        } catch {
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
            } catch {
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
