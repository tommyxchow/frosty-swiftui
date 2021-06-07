//
//  ChatView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/31/21.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel = ChatViewModel()
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10.0) {
                    ForEach(viewModel.messages, id: \.self) { message in
                        if let pair = message {
                            viewModel.emoteMessage(pair)
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
            viewModel.start()
        }
        .onDisappear {
            viewModel.end()
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
