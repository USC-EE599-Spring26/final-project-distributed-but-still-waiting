//
//  CareKitTaskView.swift
//  OCKSample
//
//  Created by Jai Shah on 28/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct CareKitTaskView: View {
    @Environment(\.careStore) var careStore
	// MARK: Navigation
	@State var isShowingAlert = false
	@State var isAddingTask = false

	// MARK: View
	@StateObject var viewModel = NewTaskViewModel()
    private let sfSymbols: [String] = [
        "pills.fill",
        "bandage.fill",
        "stethoscope",
        "heart.fill",
        "bed.double",
        "figure.walk",
        "cross.case.fill",
        "waveform.path.ecg",
        "syringe.fill",
        "thermometer"
    ]

	var body: some View {

		NavigationView {
			Form {
                Section("Card") {
                    Picker("Card View", selection: $viewModel.selectedCardType) {
                        ForEach(TaskCardType.allCases) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                }

                Section("Details") {
                    TextField("Title", text: $viewModel.title)

                    if showsInstructions {
                        TextField("Instructions", text: $viewModel.instructions)
                    }
                }

                cardSpecificFields

                Section("Icon") {
                    Picker("Icon", selection: $viewModel.asset) {
                        ForEach(sfSymbols, id: \.self) { symbol in
                            HStack {
                                Image(systemName: symbol)
                                    .foregroundColor(.accentColor)
                            }
                            .tag(symbol)
                        }
                    }
#if os(watchOS)
                    .pickerStyle(.navigationLink)
#else
                    .pickerStyle(.menu)
#endif
                }
                Stepper("Priority: \(viewModel.priority)", value: $viewModel.priority, in: 1...100)
                Section(header: Text("Care Plan")) {
                    Picker("Care Plan", selection: $viewModel.selectedCarePlanUUID) {
                        Text("None").tag(UUID?.none)

                        ForEach(viewModel.availableCarePlans, id: \.uuid) { plan in
                            Text(plan.title )
                                .tag(plan.uuid)
                        }
                    }
                }
                .onAppear {
                    Task {
                        await viewModel.loadCarePlans(store: careStore)
                    }
                }
                Section("Task") {
                    Button("Add") {
                        addTask {
                            await viewModel.addTask()
                        }
                    }.alert(
                        "Task has been added",
                        isPresented: $isShowingAlert
                    ) {
                        Button("OK") {
                            isShowingAlert = false
                        }
                    }.disabled(isAddingTask || !viewModel.canAddTask)

                    if let error = viewModel.error {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    // MODIFIED
    @ViewBuilder
    private var cardSpecificFields: some View {
        switch viewModel.selectedCardType {
        case .button:
            scheduleFields
        case .checklist:
            checklistFields
        case .instruction, .simple:
            scheduleFields
        case .healthKitNumeric:
            healthKitFields
            scheduleFields
        }
    }

    private var showsInstructions: Bool {
        switch viewModel.selectedCardType {
        case .button, .checklist, .instruction, .simple:
            return true
        case .healthKitNumeric:
            return false
        }
    }

    private var scheduleFields: some View {
        Section("Schedule") {
            DatePicker(
                "Starts",
                selection: $viewModel.scheduleDate,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    private var checklistFields: some View {
        Section("Checklist Items") {
            ForEach(viewModel.checklistItems.indices, id: \.self) { index in
                TextField("Item", text: $viewModel.checklistItems[index])
            }
            .onDelete { offsets in
                viewModel.removeChecklistItems(at: offsets)
            }

            Button("Add Item") {
                viewModel.addChecklistItem()
            }
        }
    }

    private var healthKitFields: some View {
        Section("HealthKit") {
            Picker("Quantity", selection: $viewModel.healthKitQuantity) {
                ForEach(HealthKitQuantityOption.allCases) { quantity in
                    Text(quantity.rawValue)
                        .tag(quantity)
                }
            }

            Picker("Unit", selection: $viewModel.healthKitUnit) {
                ForEach(HealthKitUnitOption.allCases) { unit in
                    Text(unit.rawValue)
                        .tag(unit)
                }
            }

            Picker("Aggregation", selection: $viewModel.healthKitAggregation) {
                ForEach(HealthKitAggregationOption.allCases) { aggregation in
                    Text(aggregation.rawValue)
                        .tag(aggregation)
                }
            }
        }
    }

    // MARK: Helpers
    func addTask(_ task: @escaping (() async -> Bool)) {
        isAddingTask = true
        Task {
            let didAddTask = await task()
            isAddingTask = false
            isShowingAlert = didAddTask
        }
    }

}

#Preview {
    CareKitTaskView()
}
