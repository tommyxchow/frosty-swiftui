//
//  SettingsView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/8/21.
//

import Nuke
import NukeUI
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var auth: Authentication
    @EnvironmentObject private var settings: Settings

    var body: some View {
        Form {
            Section("Current User") {
                if let user = auth.user, auth.isLoggedIn {
                    HStack {
                        LazyImage(source: user.profileImageUrl, resizingMode: .aspectFit)
                            .frame(width: 30)
                        Text(user.displayName)
                    }
                    Button("Log Out") {
                        Task {
                            await auth.logout()
                        }
                    }
                } else {
                    Button("Login") {
                        auth.login()
                    }
                }
            }
            Section("Cache") {
                Button("Clear Image Cache") {
                    ImageCache.shared.removeAll()
                }
            }
            Section("Debug") {
                Button("Clear Tokens") {
                    auth.clearTokens()
                }
            }
            Section("Video") {
                Toggle("Enable Video", isOn: $settings.videoEnabled)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Authentication())
            .environmentObject(Settings())
    }
}
