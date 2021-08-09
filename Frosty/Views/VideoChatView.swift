//
//  VideoChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI

struct VideoChatView: View {
    let channelName: String

    var body: some View {
        VStack(spacing: 0) {
            VideoView(channelName: channelName)
            ChatView(channelName: channelName)
        }
        .navigationTitle(channelName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VideoChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoChatView(channelName: Channel.sampleChannels[0].userName)
                .environmentObject(Authentication())
        }
    }
}
