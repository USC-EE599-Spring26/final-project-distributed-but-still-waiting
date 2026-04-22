//
//  TwoButtonCardView.swift
//  OCKSample
//
//  Created by Student on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitEssentials
import CareKit
import CareKitStore
import CareKitUI
import os.log
import SwiftUI

struct TwoButtonCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    var body: some View {
        CardView {
            VStack(alignment: .leading) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                event.instructionsText
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                    .padding(.vertical)

                VStack(alignment: .center) {
                    HStack(alignment: .center, spacing: 12) {
                        Button(action: {
                            saveSelectedValue(isPositive: true)
                        }) {
                            RectangularCompletionView(
                                isComplete: isPositiveSelected
                            ) {
                                Spacer()
                                Text(positiveButtonText)
                                    .foregroundColor(positiveForegroundColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                Spacer()
                            }
                        }
                        .buttonStyle(NoHighlightStyle())

                        Button(action: {
                            saveSelectedValue(isPositive: false)
                        }) {
                            RectangularCompletionView(
                                isComplete: isNegativeSelected
                            ) {
                                Spacer()
                                Text(negativeButtonText)
                                    .foregroundColor(negativeForegroundColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                Spacer()
                            }
                        }
                        .buttonStyle(NoHighlightStyle())
                    }
                }
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var savedButtonValue: Int? {
        event.outcome?.values.first?.integerValue
    }

    private var isPositiveSelected: Bool {
        savedButtonValue == 1
    }

    private var isNegativeSelected: Bool {
        savedButtonValue == 0
    }

    private var positiveButtonText: LocalizedStringKey {
        LocalizedStringKey(positiveButtonTitleKey)
    }

    private var negativeButtonText: LocalizedStringKey {
        LocalizedStringKey(negativeButtonTitleKey)
    }

    private var positiveForegroundColor: Color {
        isPositiveSelected && !isNegativeSelected ? .accentColor : .white
    }

    private var negativeForegroundColor: Color {
        isNegativeSelected && !isPositiveSelected ? .accentColor : .white
    }

    private var positiveButtonTitleKey: String {
        buttonTitleKey(for: Constants.twoButtonPositiveTitleKey, defaultValue: "HIGH_ENERGY")
    }

    private var negativeButtonTitleKey: String {
        buttonTitleKey(for: Constants.twoButtonNegativeTitleKey, defaultValue: "LOW_ENERGY")
    }

    private func buttonTitleKey(for key: String, defaultValue: String) -> String {
        let userInfo = (event.task as? CareTask)?.userInfo
        return userInfo?[key] ?? defaultValue
    }

    private func saveSelectedValue(isPositive: Bool) {
        Task {
            do {
                guard event.isComplete else {
                    let selectedValue = isPositive ? 1 : 0
                    let newOutcomeValue = OCKOutcomeValue(selectedValue)
                    let newValues = savedButtonValue == selectedValue ? [] : [newOutcomeValue]
                    let updatedOutcome = try await saveOutcomeValues(
                        newValues,
                        event: event
                    )
                    Logger.twoButtonCardView.info(
                        "Updated event by setting outcome values: \(updatedOutcome.values)"
                    )
                    return
                }

                let updatedOutcome = try await saveOutcomeValues(
                    [],
                    event: event
                )

                Logger.twoButtonCardView.info(
                    "Updated event by removing outcome values: \(updatedOutcome.values)"
                )
            } catch {
                Logger.twoButtonCardView.error(
                    "Error saving value: \(error)"
                )
            }
        }
    }
}

#if !os(watchOS)

extension TwoButtonCardView: EventViewable {

    public init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(
            event: event
        )
    }
}

#endif

struct TwoButtonCardView_Previews: PreviewProvider {
    static var store = Utility.createPreviewStore()
    static var query: OCKEventQuery {
        var query = OCKEventQuery(for: Date())
        query.taskIDs = [TaskID.energy]
        return query
    }

    static var previews: some View {
        VStack {
            @CareStoreFetchRequest(query: query) var events
            if let event = events.latest.first {
                TwoButtonCardView(event: event.result)
            }
        }
        .environment(\.careStore, store)
        .padding()
    }
}
