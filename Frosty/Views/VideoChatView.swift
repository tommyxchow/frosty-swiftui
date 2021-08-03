//
//  VideoChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI

struct VideoChatView: View {
    let streamer: StreamerInfo
    @State var text = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VideoView(streamer: streamer)
            ChatView(streamer: streamer)
            TextField(
                "Send messsage",
                text: $text
            )
                .focused($isFocused)
        }
        .navigationTitle(streamer.userName)
        .navigationBarTitleDisplayMode(.inline)
        .textFieldStyle(.roundedBorder)
        .onTapGesture {
            isFocused = false
        }
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
