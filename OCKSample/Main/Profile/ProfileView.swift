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
import UIKit

struct ProfileView: View {
    @Environment(\.tintColorFlip) var tintColorFlip
    private static var query = OCKPatientQuery(for: Date())
    @CareStoreFetchRequest(query: query) private var patients
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel
    @State var isPresentingAddTask = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color(tintColorFlip)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 180, height: 180)
                            .shadow(color: Color(tintColorFlip), radius: 20, x: 0, y: 8)

                        let initials = String(viewModel.firstName.prefix(1) + viewModel.lastName.prefix(1))
                        Text(initials.isEmpty ? "?" : initials.uppercased())
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    // Form fields
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("First Name", text: $viewModel.firstName)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .shadow(radius: 4, x: 0, y: 2)

                            TextField("Last Name", text: $viewModel.lastName)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .shadow(radius: 4, x: 0, y: 2)

                            DatePicker("Birthday", selection: $viewModel.birthday, displayedComponents: [.date])
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .shadow(radius: 4, x: 0, y: 2)
                        }

                        // Save button
                        Button(action: {
                            Task {
                                do {
                                    try await viewModel.saveProfile()
                                } catch {
                                    Logger.profile.error("Error saving profile: \(error.localizedDescription)")
                                }
                            }
                        }, label: {
                            Text("Save Profile")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 300, minHeight: 50)
                        })
                        .background(Color.accentColor)
                        .cornerRadius(15)

                        // Log out button
                        Button(action: {
                            Task {
                                await loginViewModel.logout()
                            }
                        }, label: {
                            Text("Log Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 300, minHeight: 50)
                        })
                        .background(Color(.systemRed))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 24)
                .onReceive(patients.publisher) { publishedPatient in
                    viewModel.updatePatient(publishedPatient.result)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Task") {
                        isPresentingAddTask = true
                    }
                    .sheet(isPresented: $isPresentingAddTask) {
                        CareKitTaskView()
                    }
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .environment(\.careStore, Utility.createPreviewStore())
    }
}