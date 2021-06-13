//
//  VideoView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/6/21.
//

import SwiftUI
import AVKit

struct VideoView: View {
    
    var body: some View {
        let player = AVPlayer(url:  URL(string:"")!)
        VideoPlayer(player: player, videoOverlay: {})
            .aspectRatio(1.77777777778, contentMode: .fit)
            .onAppear {
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
