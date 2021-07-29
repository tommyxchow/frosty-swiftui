//
//  VideoChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI

struct VideoChatView: View {
    let streamer: StreamerInfo
    var body: some View {
        VStack {
            VideoView(streamer: streamer)
            ChatView(streamer: streamer)
        }
        .navigationTitle(streamer.userName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VideoChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoChatView(streamer: StreamerInfo.data[0])
                .environmentObject(Authentication())
        }
    }
}
