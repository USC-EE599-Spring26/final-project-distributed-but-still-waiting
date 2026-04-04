//
//  MyContactView.swift
//  OCKSample
//
//  Created by Jai Shah on 02/04/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import UIKit
import CareKit
import CareKitStore
import os.log

struct MyContactView: UIViewControllerRepresentable {
	@Environment(\.careStore) var careStore
    let profileImage: UIImage?
    let name: String

	func makeUIViewController(context: Context) -> some UIViewController {
		let viewController = createViewController()
//		let navigationController = UINavigationController(
//			rootViewController: viewController
//		)
//		return navigationController
        return viewController

	}

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if let vcon = uiViewController as? MyContactViewController {
            vcon.update(profileImage: profileImage, name: name)
        }
    }

	func createViewController() -> UIViewController {
		let viewController = MyContactViewController(
            store: careStore,
            profileImage: profileImage,
            name: name)
		return viewController
	}
}

struct MyContactView_Previews: PreviewProvider {

	static var previews: some View {
		MyContactView( profileImage: UIImage(systemName: "person.fill"),
                       name: "Sample")
			.environment(\.careStore, Utility.createPreviewStore())
			.accentColor(Color.accentColor)
	}
}
