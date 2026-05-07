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
        "checkmark.circle.fill",
        "checklist",
        "book.closed.fill",
        "square.grid.2x2.fill",
        "pills.fill",
        "bandage.fill",
        "stethoscope",
        "heart.fill",
        "flame.fill",
        "scalemass.fill",
        "bed.double",
        "figure.walk",
        "figure.walk.motion",
        "cross.case.fill",
        "waveform.path.ecg",
        "syringe.fill",
        "thermometer"
    ]

    var body: some View {

        NavigationView {
            Form {
                Section(String(localized: "ADD_TASK_CARD_SECTION")) {
                    Picker(String(localized: "ADD_TASK_CARD_VIEW"), selection: $viewModel.selectedCardType) {
                        ForEach(TaskCardType.allCases) { item in
                            Text(item.displayTitle)
                                .tag(item)
                        }
                    }
                }

                Section(String(localized: "ADD_TASK_DETAILS_SECTION")) {
                    TextField(String(localized: "ADD_TASK_TITLE"), text: $viewModel.title)

                    if showsInstructions {
                        TextField(String(localized: "ADD_TASK_INSTRUCTIONS"), text: $viewModel.instructions)
                    }
                }

                cardSpecificFields

                Section(String(localized: "ADD_TASK_ICON_SECTION")) {
                    Picker(String(localized: "ADD_TASK_ICON"), selection: $viewModel.asset) {
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
                Stepper(
                    String(format: String(localized: "ADD_TASK_PRIORITY_FORMAT"), viewModel.priority),
                    value: $viewModel.priority,
                    in: 1...100
                )
                Section(header: Text(String(localized: "CARE_PLAN"))) {
                    Picker(String(localized: "CARE_PLAN"), selection: $viewModel.selectedCarePlanUUID) {
                        Text(String(localized: "NONE")).tag(UUID?.none)

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
                Section(String(localized: "ADD_TASK_TASK_SECTION")) {
                    Button(String(localized: "ADD_TASK_ADD_BUTTON")) {
                        addTask {
                            await viewModel.addTask()
                        }
                    }.alert(
                        String(localized: "ADD_TASK_SUCCESS"),
                        isPresented: $isShowingAlert
                    ) {
                        Button(String(localized: "OK")) {
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
        case .custom, .heartRate:
            scheduleFields
        case .twoButton:
            twoButtonFields
            scheduleFields
        case .uiKitSurvey:
            surveyFields
            scheduleFields
        }
    }

    private var showsInstructions: Bool {
        switch viewModel.selectedCardType {
        case .button, .checklist, .instruction, .simple, .healthKitNumeric,
             .custom, .twoButton, .heartRate, .uiKitSurvey:
            return true
        }
    }

    private var scheduleFields: some View {
        Section(String(localized: "ADD_TASK_SCHEDULE_SECTION")) {
            DatePicker(
                String(localized: "ADD_TASK_STARTS"),
                selection: $viewModel.scheduleDate,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    private var checklistFields: some View {
        Section(String(localized: "ADD_TASK_CHECKLIST_ITEMS_SECTION")) {
            ForEach(viewModel.checklistItems.indices, id: \.self) { index in
                TextField(String(localized: "ADD_TASK_CHECKLIST_ITEM"), text: $viewModel.checklistItems[index])
            }
            .onDelete { offsets in
                viewModel.removeChecklistItems(at: offsets)
            }

            Button(String(localized: "ADD_TASK_ADD_ITEM")) {
                viewModel.addChecklistItem()
            }
        }
    }

    private var healthKitFields: some View {
        Section(String(localized: "ADD_TASK_HEALTHKIT_SECTION")) {
            Picker(String(localized: "ADD_TASK_HEALTHKIT_QUANTITY"), selection: $viewModel.healthKitQuantity) {
                ForEach(HealthKitQuantityOption.allCases) { quantity in
                    Text(quantity.displayTitle)
                        .tag(quantity)
                }
            }

            Picker(String(localized: "ADD_TASK_HEALTHKIT_UNIT"), selection: $viewModel.healthKitUnit) {
                ForEach(HealthKitUnitOption.allCases) { unit in
                    Text(unit.displayTitle)
                        .tag(unit)
                }
            }

            Picker(String(localized: "ADD_TASK_HEALTHKIT_AGGREGATION"), selection: $viewModel.healthKitAggregation) {
                ForEach(HealthKitAggregationOption.allCases) { aggregation in
                    Text(aggregation.displayTitle)
                        .tag(aggregation)
                }
            }
        }
    }

    private var twoButtonFields: some View {
        Section(String(localized: "ADD_TASK_TWO_BUTTON_SECTION")) {
            TextField(
                String(localized: "ADD_TASK_TWO_BUTTON_POSITIVE"),
                text: $viewModel.twoButtonPositiveTitle
            )
            TextField(
                String(localized: "ADD_TASK_TWO_BUTTON_NEGATIVE"),
                text: $viewModel.twoButtonNegativeTitle
            )
        }
    }

    private var surveyFields: some View {
        Section(String(localized: "ADD_TASK_SURVEY_SECTION")) {
            Picker(
                String(localized: "ADD_TASK_SURVEY_TYPE"),
                selection: $viewModel.selectedSurveyType
            ) {
                ForEach(SelectableSurveyType.allCases) { surveyType in
                    Text(surveyType.displayTitle)
                        .tag(surveyType)
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
