//
//  ChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI

// FIXME: Chat occasionally black-screens for a second.

struct ChatView: View {
    let channelName: String
    @EnvironmentObject private var auth: Authentication
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isFocused: Bool
    @State var text = ""

    var body: some View {
        GeometryReader { geoProxy in
            ScrollViewReader { scrollProxy in
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
                        if !messages.isEmpty, viewModel.autoScrollEnabled {
                            scrollProxy.scrollTo(messages[messages.endIndex - 1])
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    if viewModel.autoScrollEnabled == false, !viewModel.messages.isEmpty {
                        Button("Resume Scroll") {
                            viewModel.autoScrollEnabled = true
                            scrollProxy.scrollTo(viewModel.messages[viewModel.messages.endIndex - 1])
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 5.0)
                    }
                }
            }
        }
        .padding([.bottom, .horizontal], 5.0)
        .onTapGesture {
            isFocused = false
        }
        .simultaneousGesture(DragGesture().onChanged { value in
            if value.translation.height > 0 {
                viewModel.autoScrollEnabled = false
            }
        })
        .task {
            await viewModel.start(
                token: auth.token!,
                user: auth.user?.login ?? "justinfan888",
                channelName: channelName
            )
        }
        .onDisappear {
            viewModel.end()
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                if auth.isLoggedIn {
                    ChatTextFieldView(
                        isFocused: _isFocused,
                        viewModel: viewModel,
                        user: auth.user!,
                        channelName: channelName
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
