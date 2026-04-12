//
//  Profile.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitEssentials
import ParseSwift
import SwiftUI
import os.log

@MainActor
// swiftlint:disable type_body_length
class ProfileViewModel: ObservableObject {

	// MARK: Public read/write properties

	@Published var firstName = ""
	@Published var lastName = ""
	@Published var birthday = Date()
	@Published var sex: OCKBiologicalSex = .other("other")
	@Published var sexOtherField = "other"
	@Published var note = ""
	@Published var street = ""
	@Published var city = ""
	@Published var state = ""
	@Published var zipcode = ""
	@Published var country = ""
	@Published var isShowingSaveAlert = false
    @Published var allergies = ""
    @Published var emailAddresses = ""
    @Published var messagingNumbers = ""
    @Published var phoneNumbers = ""
    @Published var otherContactInfo = ""
	@Published var isPresentingAddTask = false
	@Published var isPresentingContact = false
	@Published var isPresentingImagePicker = false
	@Published var currentStreak: Int = 0
	@Published var isProfileCreated: Bool = false
	@Published var badges: [Badge] = []
	@Published private(set) var currentProfileID: String?
	@Published var profileUIImage = UIImage(systemName: "person.fill") {
		willSet {
			guard self.profileUIImage != newValue,
				let inputImage = newValue else {
				return
			}

			if !isSettingProfilePictureForFirstTime {
				Task {
					guard var currentUser = (try? await User.current()),
						  let image = inputImage.jpegData(compressionQuality: 0.25) else {
						Logger.profile.error("User is not logged in or could not compress image")
						return
					}

					let newProfilePicture = ParseFile(name: "profile.jpg", data: image)
					// Use `.set()` to update ParseObject's that have already been saved before.
					currentUser = currentUser.set(\.profilePicture, to: newProfilePicture)
					do {
						_ = try await currentUser.save()
						Logger.profile.info("Saved updated profile picture successfully.")
					} catch {
						Logger.profile.error("Could not save profile picture: \(error.localizedDescription)")
					}
				}
			}
		}
	}
	@Published private(set) var error: Error?
	private(set) var alertMessage = "All changes saved successfully!"
	private var contact: OCKContact? // TOD: need to publish contact updates like patient

	// MARK: Private read/write properties
	private var isSettingProfilePictureForFirstTime = true

	// MARK: Lifecycle

	init() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleStreakUpdate),
			name: .streakUpdated,
			object: nil
		)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc private func handleStreakUpdate() {
		loadStreak()
	}

	// MARK: Properties

    var patient: OCKPatient? {
            willSet {
                if let currentFirstName = newValue?.name.givenName {
                    firstName = currentFirstName
                } else {
                    firstName = ""
                }
                if let currentLastName = newValue?.name.familyName {
                    lastName = currentLastName
                } else {
                    lastName = ""
                }
                if let currentBirthday = newValue?.birthday {
                    birthday = currentBirthday
                } else {
                    birthday = Date()
                }
                if let currentAllergies = newValue?.allergies {
                    allergies = currentAllergies[0]
                } else {
                    allergies = ""
                }
            }
        }

	// MARK: Helpers (public)

	func loadBadges() {
		badges = BadgeManager.shared.getBadges()
		Logger.profile.debug("Loaded \(self.badges.count, privacy: .public) badges")
	}

	func loadStreak() {
		currentStreak = StreakManager.shared.getCurrentStreak()
		Logger.profile.debug("Current streak loaded: \(self.currentStreak, privacy: .public)")
		loadBadges()
	}

	func loadCurrentProfileID() async {
		currentProfileID = try? await Utility.getRemoteClockUUID().uuidString
	}

	func updatePatient(_ patient: OCKAnyPatient) {
		guard let patient = patient as? OCKPatient,
			  let currentProfileID,
			  patient.id == currentProfileID,
			  // Only update if we have a newer version.
			  patient.uuid != self.patient?.uuid else {
			return
		}
		self.patient = patient

		// Fetch the profile picture if we have a patient.
		Task {
			do {
				try await fetchProfilePicture()
			} catch {
				Logger.profile.error("Failed to fetch profile picture: \(error.localizedDescription)")
			}
		}
	}

	func updateContact(_ contact: OCKAnyContact) {
		guard let contact = contact as? OCKContact,
			  let currentProfileID,
			  contact.id == currentProfileID,
			  // Only update if we have a newer version.
			  contact.uuid != self.contact?.uuid else {
			return
		}
		self.contact = contact
		self.isProfileCreated = true
        self.street = contact.address?.street ?? ""
        self.city = contact.address?.city ?? ""
        self.state = contact.address?.state ?? ""
        self.zipcode = contact.address?.postalCode ?? ""
        self.emailAddresses = contact.emailAddresses?.first?.value ?? ""
        self.messagingNumbers = contact.messagingNumbers?.first?.value ?? ""
        self.phoneNumbers = contact.phoneNumbers?.first?.value ?? ""
        self.otherContactInfo = contact.otherContactInfo?.first?.value ?? ""
	}

	@MainActor
	private func fetchProfilePicture() async throws {

		 // Profile pics are stored in Parse User.
		guard let currentUser = (try? await User.current().fetch()) else {
			Logger.profile.error("User is not logged in")
			return
		}

		if let pictureFile = currentUser.profilePicture {

			// Download picture from server if needed
			do {
				let profilePicture = try await pictureFile.fetch()
				guard let path = profilePicture.localURL?.relativePath else {
					Logger.profile.error("Could not find relative path for profile picture.")
					return
				}
				self.profileUIImage = UIImage(contentsOfFile: path)
			} catch {
				Logger.profile.error("Could not fetch profile picture: \(error.localizedDescription).")
			}
		}
		self.isSettingProfilePictureForFirstTime = false
	}

	// MARK: User intentional behavior

	@MainActor
	func saveProfile() async {
		alertMessage = "All changes saved successfully!"
		do {
			try await savePatient()
			try await saveContact()
		} catch {
			alertMessage = "Could not save profile: \(error)"
		}
		isShowingSaveAlert = true // Make alert pop up for user.
		await MainActor.run {
			self.loadStreak()
		}
	}

    @MainActor
        func savePatient() async throws {
            if var patientToUpdate = patient {
                // If there is a currentPatient that was fetched, check to see if any of the fields changed
                var patientHasBeenUpdated = false

                if patient?.name.givenName != firstName {
                    patientHasBeenUpdated = true
                    patientToUpdate.name.givenName = firstName
                }

                if patient?.name.familyName != lastName {
                    patientHasBeenUpdated = true
                    patientToUpdate.name.familyName = lastName
                }

                if patient?.birthday != birthday {
                    patientHasBeenUpdated = true
                    patientToUpdate.birthday = birthday
                }

                if patient?.sex != sex {
                    patientHasBeenUpdated = true
                    patientToUpdate.sex = sex
                }

                // Temp allergies
                if patient?.allergies != [allergies] {
                    patientHasBeenUpdated = true
                    patientToUpdate.allergies = [allergies]
                }

                let notes = [OCKNote(author: firstName,
                                     title: "New Note",
                                     content: note)]
                if patient?.notes != notes {
                    patientHasBeenUpdated = true
                    patientToUpdate.notes = notes
                }

                if patientHasBeenUpdated {
                    _ = try await AppDelegateKey.defaultValue?.store.updateAnyPatient(patientToUpdate)
                    Logger.profile.info("Successfully updated patient")
                }

            } else {
			guard let remoteUUID = (try? await Utility.getRemoteClockUUID())?.uuidString else {
				Logger.profile.error("The user currently is not logged in")
				return
			}

			var newPatient = OCKPatient(id: remoteUUID,
										givenName: firstName,
										familyName: lastName)
			newPatient.birthday = birthday

			// This is new patient that has never been saved before
			_ = try await AppDelegateKey.defaultValue?.store.addAnyPatient(newPatient)
			Logger.profile.info("Successfully saved new patient")
		}
	}

	@MainActor
	func saveContact() async throws {

		if var contactToUpdate = contact {
			// If a current contact was fetched, check to see if any of the fields have changed

			var contactHasBeenUpdated = false

			// Since OCKPatient was updated earlier, we should compare against this name
			if let patientName = patient?.name,
				contact?.name != patient?.name {
				contactHasBeenUpdated = true
				contactToUpdate.name = patientName
			}

			// Create a mutable temp address to compare
			let potentialAddress = OCKPostalAddress(
				street: street,
				city: city,
				state: state,
				postalCode: zipcode,
				country: country
			)
			if contact?.address != potentialAddress {
				contactHasBeenUpdated = true
				contactToUpdate.address = potentialAddress
			}
            // Create a mutable temp email address to compare
                        let potentialEmail = [OCKLabeledValue(label: "email", value: emailAddresses)]

                        if contact?.emailAddresses != potentialEmail {
                            contactHasBeenUpdated = true
                            contactToUpdate.emailAddresses = potentialEmail
                        }

                        // Create a mutable temp messaging number to compare
                        let potentialMessaging = [OCKLabeledValue(label: "message", value: messagingNumbers)]

                        if contact?.messagingNumbers != potentialMessaging {
                            contactHasBeenUpdated = true
                            contactToUpdate.messagingNumbers = potentialMessaging
                        }

                        // Create a mutable temp phone number to compare
                        let potentialPhone = [OCKLabeledValue(label: "phone", value: phoneNumbers)]

                        if contact?.phoneNumbers != potentialPhone {
                            contactHasBeenUpdated = true
                            contactToUpdate.phoneNumbers = potentialPhone
                        }

                        // Create a mutable temp other contact info to compare
                        let potentialOther = [OCKLabeledValue(label: "other", value: otherContactInfo)]

                        if contact?.otherContactInfo != potentialOther {
                            contactHasBeenUpdated = true
                            contactToUpdate.otherContactInfo = potentialOther
                        }

			if contactHasBeenUpdated {
				_ = try await AppDelegateKey.defaultValue?.store.updateAnyContact(contactToUpdate)
				Logger.profile.info("Successfully updated contact")
			}

		} else {

			guard let remoteUUID = (try? await Utility.getRemoteClockUUID())?.uuidString else {
				Logger.profile.error("The user currently is not logged in")
				return
			}

			guard let patientName = self.patient?.name else {
				Logger.profile.info("The patient did not have a name.")
				return
			}

			// Added code to create a contact for the respective signed up user
			let newContact = OCKContact(
				id: remoteUUID,
				name: patientName,
				carePlanUUID: nil
			)

			_ = try await AppDelegateKey.defaultValue?.store.addAnyContact(newContact)
			Logger.profile.info("Successfully saved new contact")
		}
	}

	static func queryPatient() -> OCKPatientQuery {
		OCKPatientQuery(for: Date())
	}

	static func queryContacts() -> OCKContactQuery {
		OCKContactQuery(for: Date())
	}

}
