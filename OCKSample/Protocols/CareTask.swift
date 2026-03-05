//
//  CareTask.swift
//  OCKSample
//
//  Created by Jai Shah on 05/03/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

protocol CareTask {
    var id: String { get }
    var userInfo: [String: String]? { get set }
    var card: CareKitCard { get set }
    var priority: Int { get set }

}

extension CareTask {
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
    var priority: Int {
        get {
            guard let priorityString = userInfo?["priority"],
                  let priorityValue = Int(priorityString) else {
                return Int.max
            }
            return priorityValue
        }

        set {
            if userInfo == nil {
                userInfo = [:]
            }
            userInfo?["priority"] = "\(newValue)"
        }
    }
}
