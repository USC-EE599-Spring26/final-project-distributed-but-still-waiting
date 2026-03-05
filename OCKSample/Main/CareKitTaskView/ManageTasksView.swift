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

    @StateObject var viewModel = CareKitTaskViewModel()

    var body: some View {

        List {
            ForEach(Array(viewModel.tasks), id: \.id) { task in
                HStack {
                    VStack(alignment: .leading) {
                        Text(task.title ?? "Untitled")

                        if let priority = (task as? CareTask)?.priority {
                            Text("Priority: \(priority)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteTask(task: task)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .task {
            await viewModel.fetchTasks()
        }
    }
}
