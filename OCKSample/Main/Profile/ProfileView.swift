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
    @CareStoreFetchRequest(query: query()) private var patients
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.accentColor, Color(tintColorFlip)],
                            startPoint: .topLeading,
                                       endPoint: .bottomTrailing
                    )
                )
                    .frame(width: 180, height: 180)
                    .shadow(color: Color(tintColorFlip), radius: 20, x: 0, y: 8)
                let initials = String(viewModel.firstName.prefix((1)) + String(viewModel.lastName.prefix(1)))
                Text(initials.isEmpty ? "?" : initials.uppercased())
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                VStack(alignment: .leading) {
                    TextField(
                        "GIVEN_NAME",
                        text: $viewModel.firstName
                    )
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)

                    TextField(
                        "FAMILY_NAME",
                        text: $viewModel.lastName
                    )
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)

                    DatePicker(
                        "BIRTHDAY",
                        selection: $viewModel.birthday,
                        displayedComponents: [DatePickerComponents.date]
                    )
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                }

                Button(action: {
                    Task {
                        do {
                            try await viewModel.saveProfile()
                        } catch {
                            Logger.profile.error("Error saving profile: \(error)")
                        }
                    }
                }, label: {
                    Text(
                        "SAVE_PROFILE"
                    )
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
                })
                .background(Color(tintColorFlip))
                .cornerRadius(15)

                // Notice that "action" is a closure (which is essentially
                // a function as argument like we discussed in class)
                Button(action: {
                    Task {
                        await loginViewModel.logout()
                    }
                }, label: {
                    Text(
                        "LOG_OUT"
                    )
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
                })
                .background(Color.accentColor)
                .cornerRadius(15)
            }
            .onReceive(patients.publisher) { publishedPatient in
                viewModel.updatePatient(publishedPatient.result)
            }
        }
        }

    static func query() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }

}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
