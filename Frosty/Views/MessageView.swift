//
//  MessageView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/15/21.
//

import SwiftUI

struct MessageView: View {
    let message: Message
    @ObservedObject var viewModel: ChatViewModel
    var body: some View {
        viewModel.emotify(message)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(message: Message(name: "Bob", message: "hello", tags: [:]), viewModel: ChatViewModel())
    }
}
