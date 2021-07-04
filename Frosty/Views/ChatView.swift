//
//  ChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI

struct ChatView: View {
    let streamer: StreamerInfo
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var authHandler: Authentication
    @StateObject private var viewModel: ChatViewModel = ChatViewModel()
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10.0) {
                    ForEach(viewModel.messages, id: \.self) { message in
                        if let triple = message {
                            MessageView(message: triple, viewModel: viewModel)
                        }
                    }
                    .font(.footnote)
                }
                .onChange(of: viewModel.messages) { value in
                    if viewModel.messages.count > 0 {
                        scrollView.scrollTo(viewModel.messages[viewModel.messages.endIndex - 1])
                    }
                }
            }
        }
        .padding([.bottom, .horizontal], 5.0)
        .task {
            await viewModel.start(token: authHandler.userToken ?? "", user: authHandler.user?.login ?? "justinfan888", streamer: streamer)
        }
        .onDisappear {
            viewModel.end()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                async {
                    await ChatManager.getGlobalAssets(token: authHandler.userToken ?? "")
                    await ChatManager.getChannelAssets(token: authHandler.userToken ?? "", id: streamer.userId)
                }
            }
            if newPhase == .background, newPhase == .inactive {
                viewModel.chatting = false
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(streamer: StreamerInfo.data[0])
            .environmentObject(Authentication())
    }
}
