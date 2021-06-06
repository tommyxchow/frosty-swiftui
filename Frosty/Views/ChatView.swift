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
        ScrollView {
            ForEach(viewModel.messages.reversed(), id: \.self) { message in
                HStack {
                    Text(message)
                    Spacer()
                }
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
