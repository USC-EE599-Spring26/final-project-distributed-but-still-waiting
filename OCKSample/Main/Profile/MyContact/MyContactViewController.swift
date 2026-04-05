//
//  MyContactViewController.swift
//  OCKSample
//
//  Created by Jai Shah on 02/04/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import CareKitStore
import CareKitUI
import CareKit
import Contacts
import ContactsUI
import ParseSwift
import ParseCareKit
import os.log

class MyContactViewController: UIViewController {

//	fileprivate var contacts = [OCKAnyContact]()
	fileprivate let store: OCKAnyStoreProtocol
//	fileprivate let viewSynchronizer = OCKDetailedContactViewSynchronizer()
    fileprivate let profileImage: UIImage?
    fileprivate let displayName: String
    fileprivate var streak: Int
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let streakLabel = UILabel()

	/// Initialize using a store manager. All of the contacts in the store manager will be queried and dispalyed.
	///
	/// - Parameter store: The store from which to query the tasks.
	/// - Parameter viewSynchronizer: The type of view to show
    init(store: OCKAnyStoreProtocol, profileImage: UIImage?, name: String, streak: Int
	) {
		self.store = store
        self.profileImage = profileImage
        self.displayName = name
        self.streak = streak
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
//		Task {
//			try? await fetchMyContact()
//		}
        view.backgroundColor = .systemBackground

            setupUI()

	}

//	override func viewDidAppear(_ animated: Bool) {
//		Task {
//			try? await fetchMyContact()
//		}
//	}
//
//	override func appendViewController(
//		_ viewController: UIViewController,
//		animated: Bool
//	) {
//		super.appendViewController(viewController, animated: animated)
//		// Make sure this contact card matches app style when possible
//		if let carekitView = viewController.view as? OCKView {
//			carekitView.customStyle = CustomStylerKey.defaultValue
//		}
//	}
//
//	func fetchMyContact() async throws {
//
//		guard (try? await User.current()) != nil,
//			  let personUUIDString = try? await Utility.getRemoteClockUUID().uuidString else {
//			Logger.myContact.error("User not logged in")
//			self.contacts.removeAll()
//			return
//		}
//
//		var query = OCKContactQuery(for: Date())
//        query.ids = [personUUIDString]
//		query.sortDescriptors.append(.familyName(ascending: true))
//		query.sortDescriptors.append(.givenName(ascending: true))
//
//		self.contacts = try await store.fetchAnyContacts(query: query)
//		self.displayContacts()
//	}
//
//	func displayContacts() {
//		self.clear()
//		for contact in self.contacts {
//			var contactQuery = OCKContactQuery(for: Date())
//			contactQuery.ids = [contact.id]
//			contactQuery.limit = 1
//			let contactViewController = OCKDetailedContactViewController(
//				query: contactQuery,
//				store: store,
//				viewSynchronizer: viewSynchronizer
//			)
//			self.appendViewController(contactViewController, animated: false)
//		}
//	}
    func update(profileImage: UIImage?, name: String) {
        imageView.image = profileImage ?? UIImage(systemName: "person.fill")
        nameLabel.text = name.isEmpty ? "Your Name" : name
        streakLabel.text = "🔥 \(streak) day streak"
    }

    func setupUI() {

        imageView.image = profileImage ?? UIImage(systemName: "person.fill")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.text = displayName.isEmpty ? "Your Name" : displayName
        nameLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)
        view.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        let streakLabel = UILabel()
        streakLabel.text = "🔥 \(streak) day streak"
        streakLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        streakLabel.textAlignment = .center
        streakLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(streakLabel)

        NSLayoutConstraint.activate([
            streakLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            streakLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

}
