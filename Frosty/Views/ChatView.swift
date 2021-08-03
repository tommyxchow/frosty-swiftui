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
    @State private var autoScroll = true
    
    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10.0) {
                        ForEach(viewModel.messages, id: \.self) { message in
                            if let triple = message {
                                MessageView(viewModel: viewModel, message: viewModel.beautify(triple), size: proxy.size)
                            }
                        }
                    }
                    .onChange(of: viewModel.messages) { value in
                        if viewModel.messages.count > 0, autoScroll {
                            scrollView.scrollTo(viewModel.messages[viewModel.messages.endIndex - 1])
                        }
                    }
                }
            }
        }
        .simultaneousGesture(DragGesture().onChanged({ value in
            if value.translation.height > 0 {
                autoScroll = false
            }
        }))
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
                    autoScroll = true
                }, label: {
                    Text("Auto Scroll")
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
