//
//  ChatBoxView.swift
//  ChatBoxView
//
//  Created by Tommy Chow on 8/5/21.
//

import SwiftUI

struct ChatBoxView: View {
    @FocusState var isFocused: Bool
    @ObservedObject var viewModel: ChatViewModel
    let user: User
    let channelName: String
    
    var body: some View {
        HStack {
            TextField("Send messsage", text: $viewModel.chatBoxMessage)
                .focused($isFocused)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
            Button("Send") {
                viewModel.sendMessage(message: viewModel.chatBoxMessage, userName: user.displayName, channelName: channelName)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding(5)
    }
}

struct ChatBoxView_Previews: PreviewProvider {
    static var previews: some View {
        ChatBoxView(viewModel: ChatViewModel(), user: User.sampleUser, channelName: "")
    }
}
