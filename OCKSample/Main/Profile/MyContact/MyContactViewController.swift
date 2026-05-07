//
//  MyContactViewController.swift
//  OCKSample
//
//  Created by Jai Shah on 02/04/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import UIKit

class MyContactViewController: UIViewController {

    fileprivate let profileImage: UIImage?
    fileprivate let displayName: String
    fileprivate var streak: Int
    fileprivate let onSelectContact: () -> Void
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let streakLabel = UILabel()

    /// Initialize using a profile image, display name, and selection handler.
    ///
    /// - Parameter profileImage: The profile image to show.
    /// - Parameter name: The name to show.
    /// - Parameter streak: The current streak to show.
    /// - Parameter onSelectContact: Called when the profile image or name is tapped.
    init(
        profileImage: UIImage?,
        name: String,
        streak: Int,
        onSelectContact: @escaping () -> Void
    ) {
        self.profileImage = profileImage
        self.displayName = name
        self.streak = streak
        self.onSelectContact = onSelectContact
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupUI()
    }

    func update(profileImage: UIImage?, name: String, streak: Int) {
        self.streak = streak
        imageView.image = profileImage ?? UIImage(systemName: "person.fill")
        nameLabel.text = name.isEmpty ? "Your Name" : name
        streakLabel.text = "🔥 \(streak) day streak"
    }

    private func setupUI() {
        imageView.image = profileImage ?? UIImage(systemName: "person.fill")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didSelectContact))
        )

        nameLabel.text = displayName.isEmpty ? "Your Name" : displayName
        nameLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didSelectContact))
        )

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

    @objc private func didSelectContact() {
        onSelectContact()
    }
}
