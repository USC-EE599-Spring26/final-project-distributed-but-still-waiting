//
//  EnergyCardView.swift
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

struct EnergyCardView: CareKitEssentialView {
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

                        // High Energy Button
                        Button(action: {
                            saveEnergyLevel(high: true)
                        }) {
                            RectangularCompletionView(
                                isComplete: isHighEnergy
                            ) {
                                Spacer()
                                Text(highEnergyButtonText)
                                    .foregroundColor(highEnergyForegroundColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                Spacer()
                            }
                        }
                        .buttonStyle(NoHighlightStyle())

                        // Low Energy Button
                        Button(action: {
                            saveEnergyLevel(high: false)
                        }) {
                            RectangularCompletionView(
                                isComplete: isLowEnergy
                            ) {
                                Spacer()
                                Text(lowEnergyButtonText)
                                    .foregroundColor(lowEnergyForegroundColor)
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

    private var savedEnergyValue: Int? {
        event.outcome?.values.first?.integerValue
    }

    private var isHighEnergy: Bool {
        savedEnergyValue == 1
    }

    private var isLowEnergy: Bool {
        savedEnergyValue == 0
    }

    private var highEnergyButtonText: LocalizedStringKey {
        isHighEnergy ? "HIGH_ENERGY" : "HIGH_ENERGY"
    }

    private var lowEnergyButtonText: LocalizedStringKey {
        isLowEnergy ? "LOW_ENERGY" : "LOW_ENERGY"
    }

    private var highEnergyForegroundColor: Color {
        isHighEnergy && !isLowEnergy ? .accentColor : .white
    }

    private var lowEnergyForegroundColor: Color {
        isLowEnergy && !isHighEnergy ? .accentColor : .white
    }

    private func saveEnergyLevel(high: Bool) {
        Task {
            do {
                guard event.isComplete else {
                    let newOutcomeValue = OCKOutcomeValue(high ? 1 : 0)
                    let newValues = savedEnergyValue == (high ? 1 : 0) ? [] : [newOutcomeValue]
                    let updatedOutcome = try await saveOutcomeValues(
                        newValues,
                        event: event)
                    Logger.energyCardView.info(
                        "Updated event by setting outcome values: \(updatedOutcome.values)"
                    )
                    return
                }

                let updatedOutcome = try await saveOutcomeValues(
                    [],
                    event: event
                )

                Logger.energyCardView.info(
                    "Updated event by removing outcome values: \(updatedOutcome.values)"
                )
            } catch {
                Logger.energyCardView.error(
                    "Error saving value: \(error)"
                )
            }
        }
    }
}

#if !os(watchOS)

extension EnergyCardView: EventViewable {

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

struct EnergyCardView_Previews: PreviewProvider {
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
                EnergyCardView(event: event.result)
            }
        }
        .environment(\.careStore, store)
        .padding()
    }
}
