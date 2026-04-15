//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import CareKitStore
import CareKit
import os.log
import SwiftUI

struct ProfileView: View {

    @CareStoreFetchRequest(query: ProfileViewModel.queryPatient()) private var patients
    @CareStoreFetchRequest(query: ProfileViewModel.queryContacts()) private var contacts
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel
    @Environment(\.careStore) private var store
    @Environment(\.tintColorFlip) var tintColorFlip
    // MARK: Navigation
    @State var isPresentingAddTask = false
    @State var isShowingSaveAlert = false
    @State var isPresentingContact = false
    @State var isPresentingImagePicker = false
    @State var isPresentingManageTasks = false
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            Group {
                // SCROLLABLE CONTENT
                if viewModel.isProfileCreated && !isEditing {
                    VStack {
                        ScrollView {
                            VStack(spacing: 20) {
                                // PROFILE VIEW
                                MyContactView(
                                    profileImage: viewModel.profileUIImage,
                                    name: "\(viewModel.firstName) \(viewModel.lastName)",
                                    streak: viewModel.currentStreak
                                )
                                .id(viewModel.currentStreak)
                                .frame(height: 200)

                                // ACHIEVEMENTS
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("ACHIEVEMENTS")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .multilineTextAlignment(.center)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(viewModel.badges) { badge in
                                                BadgeView(badge: badge)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }

                        Button(action: {
                            Task {
                                await loginViewModel.logout()
                            }
                        }) {
                            Text("Log Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .background(Color.red)
                        .cornerRadius(15)
                        .padding()
                    }
                } else {
                    Form {
                        Section {
                            HStack {
                                Spacer()
                                ProfileImageView(viewModel: viewModel)
                                Spacer()
                            }
                        }

                        Section(header: Text("About")) {
                            TextField("First Name", text: $viewModel.firstName)
                            TextField("Last Name", text: $viewModel.lastName)
                            DatePicker(
                                "Birthday",
                                selection: $viewModel.birthday,
                                displayedComponents: [DatePickerComponents.date]
                            )
                            TextField("Allergies", text: $viewModel.allergies)
                        }

                        Section(header: Text("Contact")) {
                            TextField("Street", text: $viewModel.street)
                            TextField("City", text: $viewModel.city)
                            TextField("State", text: $viewModel.state)
                            TextField("Postal code", text: $viewModel.zipcode)
                            TextField("Email Address", text: $viewModel.emailAddresses)
                            TextField("Messaging Number", text: $viewModel.messagingNumbers)
                            TextField("Phone Number", text: $viewModel.phoneNumbers)
                            TextField("Other Contact Info", text: $viewModel.otherContactInfo)
                        }

                        Section {
                            Button(action: {
                                Task {
                                    await loginViewModel.logout()
                                }
                            }) {
                                Text("Log Out")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Done" : "Edit") {
                        if isEditing {
                            Task {
                                await viewModel.saveProfile()
                                isEditing = false
                            }
                        } else {
                            isEditing = true
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage Tasks") {
                        isPresentingManageTasks = true
                    }
                    .sheet(isPresented: $isPresentingManageTasks) {
                        ManageTasksView(store: store )
                    }
                }
            }
            .sheet(isPresented: $viewModel.isPresentingImagePicker) {
                ImagePickerView(image: $viewModel.profileUIImage)
            }
            .alert(isPresented: $viewModel.isShowingSaveAlert) {
                return Alert(title: Text("Update"),
                             message: Text(viewModel.alertMessage),
                             dismissButton: .default(Text("Ok"), action: {
                    viewModel.isShowingSaveAlert = false
                }))
            }
            .onReceive(patients.publisher) { publishedPatient in
                viewModel.updatePatient(publishedPatient.result)
            }
            .onReceive(contacts.publisher) { publishedContact in
                viewModel.updateContact(publishedContact.result)
            }
            .onAppear {
                viewModel.loadStreak()
                Task {
                    await viewModel.loadCurrentProfileID()
                    patients.latest.forEach { publishedPatient in
                        viewModel.updatePatient(publishedPatient.result)
                    }
                    contacts.latest.forEach { publishedContact in
                        viewModel.updateContact(publishedContact.result)
                    }
                }
            }
        }
    }

    struct ProfileView_Previews: PreviewProvider {
        static var previews: some View {
            ProfileView(loginViewModel: .init())
                .accentColor(Color.accentColor)
                .environment(\.careStore, Utility.createPreviewStore())
        }
    }
}
