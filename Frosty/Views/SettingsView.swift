//
//  SettingsView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/8/21.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authHandler: Authentication
    @StateObject private var loginVM: LoginViewModel = LoginViewModel()
    
    var body: some View {
        if let user = authHandler.user, authHandler.isLoggedIn {
            SettingsLoggedInView(user: user)
        } else {
            VStack {
                Button(action: {
                    loginVM.login(auth: authHandler)
                }, label: {
                    Text("Login")
                })
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Authentication())
    }
}
