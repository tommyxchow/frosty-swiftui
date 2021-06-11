//
//  ChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI

struct ChatView: View {
    let streamer: StreamerInfo
    @EnvironmentObject private var authHandler: Authentication
    @StateObject private var viewModel: ChatViewModel = ChatViewModel()
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10.0) {
                    ForEach(viewModel.messages, id: \.self) { message in
                        if let triple = message {
                            viewModel.emoteMessage(triple)
                        }
                    }
                    .font(.footnote)
                }
                .onChange(of: viewModel.messages, perform: { value in
                    scrollView.scrollTo(viewModel.messages[viewModel.messages.endIndex - 1])
                })
            }
        }
        .padding(5.0)
        .onAppear {
            print("START")
            viewModel.start(token: authHandler.userToken ?? "", user: authHandler.user?.login ?? "justinfan888", streamer: streamer.userLogin)
        }
        .onDisappear {
            print("DISAPPEAR")
            viewModel.chatting = false
            print(viewModel.chatting)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(streamer: StreamerInfo.data[0])
            .environmentObject(Authentication())
    }
}
