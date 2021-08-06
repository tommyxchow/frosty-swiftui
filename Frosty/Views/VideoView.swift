//
//  VideoView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/6/21.
//

import SwiftUI
import WebKit

struct VideoView: View {
    let channelName: String
    
    var body: some View {
        WebView(url: URL(string: "https://player.twitch.tv/?channel=\(channelName)&muted=false&parent=example.com")!)
            .aspectRatio(16 / 9, contentMode: .fit)
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView(channelName: StreamerInfo.data.first!.userLogin)
    }
}

struct WebView : UIViewRepresentable {
    
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView  {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: CGRect(), configuration: config)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}
