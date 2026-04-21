//
//  CustomFeaturedContentView.swift
//  OCKSample
//
//  Created by Jai Shah on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

#if os(iOS)
import CareKitUI
import UIKit

final class CustomFeaturedContentView: OCKFeaturedContentView {

    private let titleText: String
    private let detailText: String

    init(title: String, detail: String, image: UIImage?) {
        self.titleText = title
        self.detailText = detail
        super.init(imageOverlayStyle: .dark)

        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        label.numberOfLines = 0
        updateLabel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func styleDidChange() {
        super.styleDidChange()
        updateLabel()
    }

    private func updateLabel() {
        let text = NSMutableAttributedString(
            string: titleText,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .headline),
                .foregroundColor: UIColor.white
            ]
        )
        text.append(NSAttributedString(
            string: "\n\(detailText)",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .subheadline),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ]
        ))

        label.attributedText = text
        label.adjustsFontForContentSizeCategory = true
        accessibilityLabel = "\(titleText). \(detailText)"
    }
}

#endif
