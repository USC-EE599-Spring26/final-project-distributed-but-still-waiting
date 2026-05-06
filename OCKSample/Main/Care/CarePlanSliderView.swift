//
//  CarePlanSliderView.swift
//  OCKSample
//
//  Created by Jai Shah on 4/8/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKitUI

struct CarePlanSliderView: View {
    struct Tab: Identifiable {
        let id: UUID?
        let title: String
    }

    let carePlans: [Tab]
    @Binding var selectedID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(carePlans) { plan in
                    CarePlanTab(
                        title: plan.title,
                        isSelected: selectedID == plan.id
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedID = plan.id
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct CarePlanTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(
                            color: Color.black.opacity(isSelected ? 0.2 : 0.05),
                            radius: isSelected ? 4 : 2,
                            x: 0, y: 1
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .foregroundColor(isSelected ? .accentColor : .primary)
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .animation(.spring(), value: isSelected)
    }
}

struct CarePlanSliderView_Previews: PreviewProvider {
    static var previews: some View {
        CarePlanSliderView(
            carePlans: [
                .init(id: nil, title: "All Tasks"),
                .init(id: UUID(), title: "Mental Health"),
                .init(id: UUID(), title: "Sleep Health")
            ],
            selectedID: .constant(nil)
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
