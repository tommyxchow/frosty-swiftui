//
//  MessageView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/15/21.
//

import SwiftUI

struct MessageView: View {
    @ObservedObject var viewModel: ChatViewModel
    let message: Message
    let size: CGSize

    var body: some View {
        FlexMessage(
            message: message,
            assetToUrl: viewModel.assetToUrl,
            size: size
        )
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(viewModel: ChatViewModel(), message: Message(tags: [:], type: .PRIVMSG, message: ""), size: .zero)
    }
}
