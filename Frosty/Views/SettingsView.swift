//
//  SettingsView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/8/21.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: Authentication
    @StateObject private var loginVM: LoginViewModel = LoginViewModel()
    @StateObject private var viewModel: SettingsViewModel = SettingsViewModel()
    var body: some View {
        if let user = auth.user, auth.isLoggedIn {
            SettingsLoggedInView(user: user)
        } else {
            Button("Login", action: {
                loginVM.login(auth: auth)
            })
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Authentication())
    }
}
