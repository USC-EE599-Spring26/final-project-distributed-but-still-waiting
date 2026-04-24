//
//  MyContactView.swift
//  OCKSample
//
//  Created by Jai Shah on 02/04/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import UIKit

struct MyContactView: UIViewControllerRepresentable {
    let profileImage: UIImage?
    let name: String
    let streak: Int
    let onSelectContact: () -> Void

	func makeUIViewController(context: Context) -> some UIViewController {
		createViewController()
	}

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if let vcon = uiViewController as? MyContactViewController {
            vcon.update(profileImage: profileImage, name: name, streak: streak)
        }
    }

	func createViewController() -> UIViewController {
		let viewController = MyContactViewController(
            profileImage: profileImage,
            name: name,
            streak: streak,
            onSelectContact: onSelectContact
        )
		return viewController
	}
}

struct MyContactView_Previews: PreviewProvider {

	static var previews: some View {
		MyContactView(
            profileImage: UIImage(systemName: "person.fill"),
            name: "Sample",
            streak: 1,
            onSelectContact: {}
        )
			.environment(\.careStore, Utility.createPreviewStore())
			.accentColor(Color.accentColor)
	}
}
