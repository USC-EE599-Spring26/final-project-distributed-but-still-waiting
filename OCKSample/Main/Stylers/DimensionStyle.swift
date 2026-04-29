//
//  DimensionStyle.swift
//  OCKSample
//
//  Created by Jai Shah on 28/02/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import SwiftUI
import UIKit

struct DimensionStyler: OCKDimensionStyler {
    #if os(iOS) || os(visionOS)
    var lineWidth1: CGFloat { 5 }
    var stackSpacing1: CGFloat { 12 }
    var imageHeight2: CGFloat { 40 }
    var imageHeight1: CGFloat { 160 }
    #endif
}
