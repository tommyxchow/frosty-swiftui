//
//  StreamerListView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct StreamerListView: View {
    @EnvironmentObject var authHandler: Authentication
    @StateObject private var streamersVM = StreamerListViewModel()
    
    var body: some View {
        if let token = authHandler.userToken {
            List {
                ForEach(streamersVM.streamers, id: \.userName) { streamer in
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
                        authHandler.isLoggedIn ? streamersVM.updateFollowedStreamers(id: authHandler.user!.id, token: token) : streamersVM.updateTopStreamers(token: token)
                    }, label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    })
                }
            }
            .onAppear {
                print("REFRESHING")
                authHandler.isLoggedIn ? streamersVM.updateFollowedStreamers(id: authHandler.user!.id, token: token) : streamersVM.updateTopStreamers(token: token)
            }
        } else {
            Text("Getting token...")
                .onAppear {
                    print("GETTING TOKEN")
                    authHandler.getDefaultToken()
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
