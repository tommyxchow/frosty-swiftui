//
//  ChannelCardView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import NukeUI
import SwiftUI

struct ChannelCardView: View {
    let channel: Channel
    var body: some View {
        HStack {
            LazyImage(source: URL(string: channel.thumbnailUrl.replacingOccurrences(of: "-{width}x{height}", with: "-1024x576"))!, resizingMode: .aspectFit)
                .frame(width: 150)
            Spacer()
            VStack(alignment: .leading, spacing: 5.0) {
                Text(channel.userName)
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(channel.title)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                Text(channel.gameName)
                    .font(.footnote)
                Text("\(channel.viewerCount) viewers")
                    .font(.footnote)
            }
        }
        .padding(.vertical, 5.0)
    }
}

struct ChannelCardView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelCardView(channel: Channel.sampleChannels[1])
            .previewLayout(.sizeThatFits)
    }
}
