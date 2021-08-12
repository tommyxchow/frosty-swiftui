//
//  VideoChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI

// TODO: Add placeholder items in bottom toolbar when user is logged out.
// TODO: Shorten back button title to something like "Back".
// TODO: Use username in the navigation title instead of userlogin.

// FIXME: Blank bottom toolbars

struct VideoChatView: View {
    @EnvironmentObject var settings: Settings
    @State var isPresented = false
    let channelName: String

    var body: some View {
        VStack(spacing: 0) {
            if settings.videoEnabled {
                VideoView(channelName: channelName)
            }
            ChatView(channelName: channelName)
        }
        .navigationTitle(channelName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresented) {
            NavigationView {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Dismiss") {
                                isPresented = false
                            }
                        }
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isPresented = true
                }, label: {
                    Label("Settings", systemImage: "gearshape")
                })
            }
        }
    }
}

struct VideoChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoChatView(channelName: Channel.sampleChannels[0].userName)
                .environmentObject(Authentication())
                .environmentObject(Settings())
        }
    }
}
