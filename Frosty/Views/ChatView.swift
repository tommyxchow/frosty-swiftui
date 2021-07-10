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
                    Text("Loading emotes and connecting to chat...")
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.end()
                    async {
                        await viewModel.start(token: authHandler.userToken ?? "", user: authHandler.user?.login ?? "justinfan888", streamer: streamer)
                    }
                }, label: {
                    Text("Refresh")
                })
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
