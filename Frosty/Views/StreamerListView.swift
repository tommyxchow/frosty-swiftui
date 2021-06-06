//
//  StreamerListView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct StreamerListView: View {
    @EnvironmentObject var auth: Authentication
    @ObservedObject var viewModel = StreamerListViewModel()
    var body: some View {
        if auth.isLoggedIn {
            List {
                ForEach(viewModel.streamers, id: \.userName) { streamer in
                    NavigationLink(destination: VideoChatView()) {
                        StreamerCardView(streamer: streamer)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Live")
            .navigationBarItems(trailing: Button(action: viewModel.updateFollowedStreamers, label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }))
            .onAppear {
                viewModel.updateFollowedStreamers()
            }
        } else {
            List {
                ForEach(viewModel.streamers, id: \.userName) { streamer in
                    NavigationLink(destination: VideoChatView()) {
                        StreamerCardView(streamer: streamer)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Live")
            .navigationBarItems(leading: Button(action: auth.login, label: {
                Text("Login")
            }), trailing: Button(action: viewModel.updateFollowedStreamers, label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }))
            .onAppear {
                viewModel.updateTopStreamers()
            }
        }
    }
}

struct StreamerListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StreamerListView()
        }
    }
}
