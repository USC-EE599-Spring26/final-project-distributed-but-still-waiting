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

                            Text(task.title ?? "Untitled Task")
                                .font(.headline)

                            if let instructions = task.instructions {
                                Text(instructions)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
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
            .navigationTitle("Manage Tasks")
            .task {
                await viewModel.fetchTasks()
            }
        }
    }
}
