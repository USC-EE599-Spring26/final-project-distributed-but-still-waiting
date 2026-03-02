//
//  ColorStyler.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import SwiftUI
import UIKit

struct ColorStyler: OCKColorStyler {
    #if os(iOS) || os(visionOS)
    var label: UIColor {
        FontColorKey.defaultValue
    }
    var tertiaryLabel: UIColor {
		UIColor(Color.accentColor)
    }
    var secondaryLabel: UIColor {
        UIColor(red: 0.42, green: 0.54, blue: 0.65, alpha: 1) // brandSteel
    }
    var customGroupedBackground: UIColor {
        UIColor(red: 0.74, green: 0.87, blue: 0.99, alpha: 1)
    }
    var customBlue: UIColor {
        UIColor(red: 0.42, green: 0.54, blue: 0.65, alpha: 1)
    }
    var customGreen: UIColor {
        UIColor(red: 0.36, green: 0.63, blue: 0.54, alpha: 1)
    }
    var separator: UIColor {
        UIColor(red: 0.74, green: 0.87, blue: 0.99, alpha: 1)
    }
    #endif
}
