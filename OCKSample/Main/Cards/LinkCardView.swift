//
//  LinkCardView.swift
//  OCKSample
//  Created by Jai Shah on 4/20/26.
//

import CareKitUI
import SwiftUI

struct LinkCardView: View {
    private static let resourcesURL = "https://dmh.lacounty.gov/get-help-now/"

    var body: some View {
        LinkView(
            title: Text("Mental Health Resources"),
            detail: Text("Los Angeles County Department of Mental Health"),
            instructions: Text("Find county mental health resources and urgent support options."),
            links: [
                .website(Self.resourcesURL, title: "Get Help Now")
            ]
        )
        .frame(maxWidth: .infinity)
    }
}
