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

    @State private var isPositiveFlashing = false
    @State private var isNegativeFlashing = false

    private static let flashDuration: TimeInterval = 0.15

    var body: some View {
        CardView {
            VStack(alignment: .leading) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                VStack(alignment: .center) {
                    HStack(alignment: .center, spacing: 12) {
                        Button(action: {
                            flashPositive()
                            updateValue(by: 1)
                        }) {
                            RectangularCompletionView(
                                isComplete: isPositiveFlashing
                            ) {
                                Spacer()
                                Text(positiveButtonText)
                                    .foregroundColor(isPositiveFlashing ? .accentColor : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                Spacer()
                            }
                        }
                        .buttonStyle(NoHighlightStyle())

                        Button(action: {
                            flashNegative()
                            updateValue(by: -1)
                        }) {
                            RectangularCompletionView(
                                isComplete: isNegativeFlashing
                            ) {
                                Spacer()
                                Text(negativeButtonText)
                                    .foregroundColor(isNegativeFlashing ? .accentColor : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                Spacer()
                            }
                        }
                        .buttonStyle(NoHighlightStyle())
                    }
                }

                event.instructionsText
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                    .padding(.top)
            }
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var currentValue: Int {
        event.outcome?.values.first?.integerValue ?? 0
    }

    private var positiveButtonText: LocalizedStringKey {
        LocalizedStringKey(positiveButtonTitleKey)
    }

    private var negativeButtonText: LocalizedStringKey {
        LocalizedStringKey(negativeButtonTitleKey)
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

    private func flashPositive() {
        withAnimation(.easeOut(duration: 0.08)) {
            isPositiveFlashing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.flashDuration) {
            withAnimation(.easeIn(duration: 0.12)) {
                isPositiveFlashing = false
            }
        }
    }

    private func flashNegative() {
        withAnimation(.easeOut(duration: 0.08)) {
            isNegativeFlashing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.flashDuration) {
            withAnimation(.easeIn(duration: 0.12)) {
                isNegativeFlashing = false
            }
        }
    }

    private func updateValue(by delta: Int) {
        let proposedValue = currentValue + delta
        let newValue = max(0, proposedValue)

        guard newValue != currentValue else {
            return
        }

        Task {
            do {
                let newOutcomeValue = OCKOutcomeValue(newValue)
                let updatedOutcome = try await saveOutcomeValues(
                    [newOutcomeValue],
                    event: event
                )
                Logger.twoButtonCardView.info(
                    "Updated event value to: \(updatedOutcome.values)"
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
