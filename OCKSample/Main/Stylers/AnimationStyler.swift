//
//  AnimationStyler.swift
//  OCKSample
//
//  Created by Student on 3/3/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import SwiftUI
import UIKit

struct AnimationStyler: OCKAnimationStyler {
    #if os(iOS) || os(visionOS)
    var stateChangeDuration: Double { 0.15}
    #endif
}
