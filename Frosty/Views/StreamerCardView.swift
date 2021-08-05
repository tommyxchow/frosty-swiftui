//
//  StreamerCardView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI
import NukeUI

struct StreamerCardView: View {
    let streamer: StreamerInfo
    var body: some View {
        HStack {
            LazyImage(source: URL(string: streamer.thumbnailUrl.replacingOccurrences(of: "-{width}x{height}", with: "-1024x576"))!, resizingMode: .aspectFit)
            Spacer()
            VStack(alignment: .leading, spacing: 5.0) {
                Text(streamer.userName)
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(streamer.title)
                        .font(.subheadline)
                }
                Text(streamer.gameName)
                    .font(.footnote)
                Text("\(streamer.viewerCount) viewers")
                    .font(.footnote)
            }
        }
        .padding(.vertical, 5.0)
    }
}

struct StreamerCardView_Previews: PreviewProvider {
    static var previews: some View {
        StreamerCardView(streamer: StreamerInfo.data[1])
            .previewLayout(.sizeThatFits)
    }
}
