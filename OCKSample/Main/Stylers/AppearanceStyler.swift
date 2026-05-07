//
//  AppearanceStyler.swift
//  OCKSample
//
//  Created by Student on 3/3/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import SwiftUI
import UIKit

struct AppearanceStyler: OCKAppearanceStyler {
    #if os(iOS) || os(visionOS)
    var cornerRadius1: CGFloat { 18 }
    var cornerRadius2: CGFloat { 15 }
    var shadowOpacity1: Float { 0.1 }
    #endif
}
