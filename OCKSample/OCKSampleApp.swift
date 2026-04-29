//
//  OCKSampleApp.swift
//  OCKSample
//
//  Created by Corey Baker on 9/2/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI
import CareKit

@main
struct OCKSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.careKitStyle) var style
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.appDelegate, appDelegate)
                .careKitStyle(style)
                .onChange(of: scenePhase) {
                    if scenePhase == .active {
                        Task {
                            await StreakManager.shared.initializeStreak()
                        }
                    }
                }
        }
    }
}
