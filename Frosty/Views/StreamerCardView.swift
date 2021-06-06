//
//  StreamerCardView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct StreamerCardView: View {
    let streamer: StreamerInfo
    var body: some View {
        ZStack {
            HStack {
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
                Spacer()
                if let thumbnail = streamer.thumbnail {
                    Image(uiImage: UIImage(data: thumbnail)!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .cornerRadius(10.0)
                }
            }
        }
        .padding(5.0)
        .cornerRadius(10.0)
    }
}

struct StreamerCardView_Previews: PreviewProvider {
    static var previews: some View {
        StreamerCardView(streamer: StreamerInfo.data[1])
            .previewLayout(.sizeThatFits)
    }
}
