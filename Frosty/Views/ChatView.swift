//
//  ChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI

struct ChatView: View {
    let channelName: String
    @EnvironmentObject private var authHandler: Authentication
    @StateObject private var viewModel: ChatViewModel = ChatViewModel()
    @State private var autoScroll = true
    @FocusState private var isFocused: Bool
    @State var text = ""

    var body: some View {
        GeometryReader { geoProxy in
            ScrollViewReader { scrollProxy in
                VStack {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10.0) {
                            ForEach(viewModel.messages, id: \.self) { item in
                                if let message = item {
                                    MessageView(
                                        viewModel: viewModel,
                                        message: message,
                                        size: geoProxy.size
                                    )
                                }
                            }
                        }
                        .onChange(of: viewModel.messages) { messages in
                            if messages.count > 0, autoScroll {
                                scrollProxy.scrollTo(messages[messages.endIndex - 1])
                            }
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    if autoScroll == false {
                        Button("Resume Scroll") {
                            autoScroll = true
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                }
            }
        }
        .padding([.bottom, .horizontal], 5.0)
        .onTapGesture {
            isFocused = false
        }
        .simultaneousGesture(DragGesture().onChanged({ value in
            if value.translation.height > 0 {
                autoScroll = false
            }
        }))
        .task {
            await viewModel.start(
                token: authHandler.userToken!,
                user: authHandler.user?.login ?? "justinfan888",
                channelName: channelName
            )
        }
        .onDisappear {
            viewModel.end()
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                if let user = authHandler.user {
                    ChatTextFieldView(
                        isFocused: _isFocused,
                        viewModel: viewModel,
                        user: user, channelName: channelName
                    )
                }
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(channelName: Channel.sampleChannels[0].userLogin)
            .environmentObject(Authentication())
    }
}
