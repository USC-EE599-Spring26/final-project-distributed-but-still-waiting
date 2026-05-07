//
//  OCKHealthKitPassthroughStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore

extension OCKHealthKitPassthroughStore {

    func populateDefaultHealthKitTasks(
        _ patientUUID: UUID? = nil,
        startDate: Date = Date()
	) async throws {
        _ = patientUUID
        _ = startDate
    }
}
