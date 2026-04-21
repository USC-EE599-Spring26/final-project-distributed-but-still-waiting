//
//  LinkCardView.swift
//  OCKSample
//
//  Created by GitHub Copilot on 2026-04-18.
//

import CareKitEssentials
import CareKit
import CareKitStore
import CareKitUI
import SwiftUI
import os.log

// A SwiftUI card that displays one or more links using CareKitUI's LinkView.
struct LinkCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    var body: some View {
        CardView {
            // Use the built-in LinkView which includes its own header.
            LinkView(
                title: Text(event.title),
                detail: event.detailText,
                instructions: event.instructionsText,
                links: makeLinkItems()
            )
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private func makeLinkItems() -> [LinkItem] {
        // Prefer a URL provided in the task's userInfo under Constants.link
        if let task = event.task as? OCKTask,
           let linkString = task.userInfo?[Constants.link],
           !linkString.isEmpty {
            // If it looks like a web link, prefer the website variant
            if linkString.lowercased().hasPrefix("http") {
                return [LinkItem.website(linkString, title: String(localized: "GET_HELP_NOW"))]
            }
            // Otherwise, try to convert to URL
            if let url = URL(string: linkString) {
                return [LinkItem.url(url, title: String(localized: "GET_HELP_NOW"), symbol: "link.circle")]
            }
        }

        // Fallback: no links available
        return []
    }
}

#if !os(watchOS)
extension LinkCardView: EventViewable {
    public init?(event: OCKAnyEvent, store: any OCKAnyStoreProtocol) {
        self.init(event: event)
    }
}
#endif

struct LinkCardView_Previews: PreviewProvider {
    static var store = Utility.createPreviewStore()
    static var query: OCKEventQuery {
        var query = OCKEventQuery(for: Date())
        query.taskIDs = [TaskID.mentalHealthResources]
        return query
    }

    static var previews: some View {
        VStack {
            @CareStoreFetchRequest(query: query) var events
            if let event = events.latest.first {
                LinkCardView(event: event.result)
            }
        }
        .environment(\.careStore, store)
        .padding()
    }
}
