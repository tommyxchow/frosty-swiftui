//
//  VideoChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI
import AVKit


struct VideoChatView: View {
    var body: some View {
        VStack {
            let player = AVPlayer(url:  URL(string:"")!)
            VideoPlayer(player: player, videoOverlay: {})
                .frame(height:211)
                .onAppear(perform: {
                    player.play()
                })
            Spacer()
            ChatView()
        }
    }
}

struct VideoChatView_Previews: PreviewProvider {
    static var previews: some View {
        VideoChatView()
    }
}
