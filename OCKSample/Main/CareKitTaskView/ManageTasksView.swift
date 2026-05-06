//
//  ManageTasksView.swift
//  OCKSample
//
//  Created by Jai Shah on 05/03/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKitStore

struct ManageTasksView: View {

    @Environment(\.careStore) private var store
    @StateObject private var viewModel: ManageTasksViewModel
    @State private var isPresentingAddTask = false

    init(store: OCKAnyTaskStore) {
        _viewModel = StateObject(wrappedValue: ManageTasksViewModel(store: store))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.tasks, id: \.id) { task in
                    HStack(spacing: 12) {

                        Image(systemName: task.asset ?? "square.grid.2x2")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .frame(width: 28)

                        VStack(alignment: .leading) {

                            HStack {
                                Text(task.title ?? String(localized: "UNTITLED_TASK"))
                                    .font(.headline)

                                Spacer()

                                if let priority = (task as? CareTask)?.priority {
                                    Text(String(format: String(localized: "TASK_PRIORITY_SHORT_FORMAT"), priority))
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(6)
                                }
                            }

                            Text(viewModel.carePlanTitle(for: task))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    Task {
                        await viewModel.deleteTasks(at: offsets)
                    }
                }
            }
            .navigationTitle(String(localized: "MANAGE_TASKS"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddTask) {
                CareKitTaskView()

            }
            .task {
                await viewModel.fetchCarePlans(store: store)
                await viewModel.fetchTasks()
            }
        }
    }
}
