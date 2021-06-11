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
        let player = AVPlayer(url:  URL(string:"https://video-weaver.fra05.hls.ttvnw.net/v1/playlist/CoYEdXQRTLV_UhzWF4_4q_RSoQa5x9XB4FozqzIEnCC8g2svFROP4urcfsgl8ghlfy6oZOscxpv73p5XGewa4t3TmMQGivYjTARYtLNtgt2F2NqljIi8cbsK-DJgbiz6ki56_Ci6ED15kT51ZiAEGApHH7HVqgBrEWcGL2KSzPOH6Lg2vbvWojfRal92iMEoKhpcsRbR4vFo2EMtUM0dHlKjEVcuC61EvE0yENbfwL3fHAl7stm2p9nqKrwa-bzeB8NmgH-Z94RgBn4ppRzpjmjN6SPssthXpcWCHz1jlZyRwW4kFjzNgSGXbebsi_Q7O8-n84KEGPAz4T0Jon3AM3PbiOHI2Bk04jcek6_bzMLAoBSs72DQDVKBUHJ-NtZ7zFc1UVskY2OpyTZZcKnEDPe5ZhSPljw-vVFbVvIgnkgxpNT2b1q7pFB4Tc4uEltGD2B38nGdyYu2YIgO4JIvfO3cvd27unlTrsOLSTcu8pb-8Yi6FbiXnLwRki7ixwhzRJrTLsXTQN9qf-HAu3j-tok_m-R40k5G6OXfQP3IdciEb8fB2FD7G58wnNMPK3bpoOpVRK2Ib-cFlgVIDxSxPcPGBWFhVvjN-4-hw-pusjEh3dI7PrwkxZEuw1T6rMztDgNetX2qbDeplhIyqNDJ_5YKuJognS9_2K8jqWTbpN2Q52bwkmOz7ZMSEPlPz96UkO4Ny7qBJFZ_f6YaDCFCbxNayRR1axoXmg.m3u8")!)
        VideoPlayer(player: player, videoOverlay: {})
            .aspectRatio(1.77777777778, contentMode: .fit)
            .onAppear(perform: {
                player.play()
            })
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
