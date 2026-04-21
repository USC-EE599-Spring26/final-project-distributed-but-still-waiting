//
//  MainTabView.swift
//  OCKSample
//
//  Created by Corey Baker on 9/18/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//
// This was built using the Hacking with Swift tutorial for creating tabs with TabView and tabItem.

import CareKitStore
import CareKitUI
import SwiftUI
import os.log

struct MainTabView: View {
	@ObservedObject var loginViewModel: LoginViewModel
	@State private var selectedTab = 0

	var body: some View {
		TabView(selection: $selectedTab) {
			CareView()
				.tabItem {
					if selectedTab == 0 {
						Image(systemName: "chart.line.text.clipboard")
							.renderingMode(.template)
					} else {
						Image(systemName: "chart.line.text.clipboard.fill")
							.renderingMode(.template)
					}
				}
				.tag(0)

			InsightsView()
				.tabItem {
					if selectedTab == 1 {
						Image(systemName: "chart.pie.fill")
							.renderingMode(.template)
					} else {
						Image(systemName: "chart.pie")
							.renderingMode(.template)
					}
				}
				.tag(1)

			ContactView()
				.tabItem {
					if selectedTab == 2 {
						Image(systemName: "phone.bubble.fill")
							.renderingMode(.template)
					} else {
						Image(systemName: "phone.bubble")
							.renderingMode(.template)
					}
				}
				.tag(2)

			ProfileView(loginViewModel: loginViewModel)
				.tabItem {
					if selectedTab == 3 {
						Image(systemName: "person.circle.fill")
							.renderingMode(.template)
					} else {
						Image(systemName: "person.circle")
							.renderingMode(.template)
					}
				}
				.tag(3)
		}
        .onChange(of: selectedTab) {
            Logger.appDelegate.debug("MainTabView switched to tab: \(selectedTab, privacy: .public)")
        }
	}
}

struct MainTabView_Previews: PreviewProvider {
	static var previews: some View {
		MainTabView(loginViewModel: .init())
			.environment(\.appDelegate, AppDelegate())
			.environment(\.careStore, Utility.createPreviewStore())
			.careKitStyle(Styler())
	}
}
