//
//  TintColorFlipKey.swift
//  OCKSample
//
//  Created by Corey Baker on 9/26/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct TintColorFlipKey: EnvironmentKey {
    static var defaultValue: UIColor {
        #if os(iOS) || os(visionOS)
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return #colorLiteral(red: 0.74, green: 0.87, blue: 0.99, alpha: 1)
            }
            return #colorLiteral(red: 0.22, green: 0.29, blue: 0.35, alpha: 1)
        }
        #else
        return #colorLiteral(red: 0.74, green: 0.87, blue: 0.99, alpha: 1)
        #endif
    }
}

extension EnvironmentValues {
    var tintColorFlip: UIColor {
        self[TintColorFlipKey.self]
    }
}
