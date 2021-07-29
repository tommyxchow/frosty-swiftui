//
//  ChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI
import SDWebImageSwiftUI
import Kingfisher


struct ChatView: View {
    let streamer: StreamerInfo
    @EnvironmentObject private var authHandler: Authentication
    @StateObject private var viewModel: ChatViewModel = ChatViewModel()
    
    @State var gif = KFAnimatedImage(URL(string: "https://cdn.betterttv.net/emote/5ad22a7096065b6c6bddf7f3/2x")!)
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5.0) {
                    ForEach(viewModel.messages, id: \.self) { message in
                        if let triple = message {
                            MessageView(viewModel: viewModel, message: viewModel.beautify(triple))
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
                    Task {
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
