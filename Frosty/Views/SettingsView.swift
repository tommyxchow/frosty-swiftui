//
//  SettingsView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/8/21.
//

import SwiftUI
import NukeUI
import Nuke

struct SettingsView: View {
    @EnvironmentObject private var authHandler: Authentication
    
    var body: some View {
        List {
            Section("Current User") {
                if let user = authHandler.user, authHandler.isLoggedIn {
                    HStack {
                        LazyImage(source: user.profileImageUrl, resizingMode: .aspectFit)
                            .frame(width: 30)
                        Text(user.displayName)
                    }
                    Button("Log Out") {
                        authHandler.logout()
                    }
                } else {
                    Button("Login") {
                        authHandler.login()
                    }
                }
            }
            Section("Cache") {
                Button("Clear Image Cache") {
                    ImageCache.shared.removeAll()
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Authentication())
    }
}
