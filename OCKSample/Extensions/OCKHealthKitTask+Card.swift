//
//  OCKHealthKitTask+Card.swift
//  OCKSample
//
//  Created by Jai Shah on 28/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//


import Foundation
import CareKitStore

extension OCKHealthKitTask {

	var card: CareKitCard {
		get {
			guard let cardInfo = userInfo?[Constants.card],
				  let careKitCard = CareKitCard(rawValue: cardInfo) else {
				return .grid
			}
			return careKitCard
		}
		set {
			if userInfo == nil {
				userInfo = .init()
			}
			userInfo?[Constants.card] = newValue.rawValue
		}
	}
}
