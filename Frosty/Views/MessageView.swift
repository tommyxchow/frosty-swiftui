//
//  MessageView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/15/21.
//

import SwiftUI

struct MessageView: View {
    let message: [String]
    @ObservedObject var viewModel: ChatViewModel
    var body: some View {
        viewModel.emotify(message)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(message: ["Bob", "This is a test OMEGALUL"], viewModel: ChatViewModel())
    }
}
