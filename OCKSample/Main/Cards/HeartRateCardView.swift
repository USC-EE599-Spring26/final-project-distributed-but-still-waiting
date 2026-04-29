//
//  HeartRateCardView.swift
//  OCKSample
//
//  Created by Student on 4/29/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitEssentials
import CareKit
import CareKitStore
import CareKitUI
import SwiftUI

struct HeartRateCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }

                HStack(alignment: .lastTextBaseline) {
                    Text(averageHeartRateText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                    
                    Text("bpm")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                if let instructions = event.instructions {
                    Text(instructions)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .padding(isCardEnabled ? [.all] : [])
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var averageHeartRateText: String {
        guard let value = event.outcome?.values.first?.doubleValue else {
            return "--"
        }
        return String(format: "%.0f", value)
    }
}

#if !os(watchOS)

extension HeartRateCardView: EventViewable {

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
