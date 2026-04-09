//
//  CareKitTaskView.swift
//  OCKSample
//
//  Created by Jai Shah on 28/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct CareKitTaskView: View {

	// MARK: Navigation
	@State var isShowingAlert = false
	@State var isAddingTask = false
    @Environment(\.careStore) var careStore

	// MARK: View
	@StateObject var viewModel = CareKitTaskViewModel()
	@State var title = ""
	@State var instructions = ""
	@State var selectedCard: CareKitCard = .button
    @State var priority: Int = 100
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
    @State var asset = "pills.fill"

	var body: some View {

		NavigationView {
			Form {
				TextField("Title",
						  text: $title)
				TextField("Instructions",
						  text: $instructions)
                Section("Icon") {
                    Picker("Icon", selection: $asset) {
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
				Picker("Card View", selection: $selectedCard) {
					ForEach(CareKitCard.allCases) { item in
						Text(item.rawValue)
                    }
                }
                Stepper("Priority: \(priority)", value: $priority, in: 1...100)
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
                            await viewModel.addTask(
                                title,
                                instructions: instructions,
                                cardType: selectedCard,
                                priority: priority,
                                asset: asset
                            )
                        }
                    }.alert(
                        "Task has been added",
                        isPresented: $isShowingAlert
                    ) {
                        Button("OK") {
                            isShowingAlert = false
                        }
                    }.disabled(isAddingTask)
                }
                Section("HealthKitTask") {
                    Button("Add") {
                        addTask {
                            await viewModel.addHealthKitTask(
                                title,
                                instructions: instructions,
                                cardType: selectedCard,
                                priority: priority,
                                asset: asset
                            )
                        }
                    }.alert(
                        "HealthKitTask has been added",
                        isPresented: $isShowingAlert
                    ) {
                        Button("OK") {
                            isShowingAlert = false
                        }
                    }.disabled(isAddingTask)
                }
            }
        }
    }

    // MARK: Helpers
    func addTask(_ task: @escaping (() async -> Void)) {
        isAddingTask = true
        Task {
            await task()
            isAddingTask = false
            isShowingAlert = true
        }
    }

}

#Preview {
    CareKitTaskView()
}
