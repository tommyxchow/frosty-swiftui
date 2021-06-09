//
//  StreamerListView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct StreamerListView: View {
    @EnvironmentObject var auth: Authentication
    @StateObject private var viewModel: StreamerListViewModel = StreamerListViewModel()
    
    var body: some View {
        if let token = auth.userToken {
            List {
                ForEach(viewModel.streamers, id: \.userName) { streamer in
                    NavigationLink(destination: VideoChatView(streamer: streamer)) {
                        StreamerCardView(streamer: streamer)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Live")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        auth.isLoggedIn ? viewModel.updateFollowedStreamers(id: auth.user!.id, token: token) : viewModel.updateTopStreamers(token: token)
                    }, label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    })
                }
            }
            .onAppear {
                print("REFRESHING")
                auth.isLoggedIn ? viewModel.updateFollowedStreamers(id: auth.user!.id, token: token) : viewModel.updateTopStreamers(token: token)
            }
        } else {
            Text("Getting token...")
                .onAppear {
                    print("GETTING TOKEN")
                    auth.getDefaultToken()
                }
        }
    }
}

struct StreamerListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StreamerListView()
                .environmentObject(Authentication())
        }
    }
}
