//
//  StreamerListView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct StreamerListView: View {
    @EnvironmentObject var auth: Authentication
    @StateObject private var streamerListVM = StreamerListViewModel()
    @State private var firstTime = true
    
    var body: some View {
        if let token = auth.userToken {
            List {
                ForEach(streamerListVM.streamers, id: \.userName) { streamer in
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
                        auth.isLoggedIn ? streamerListVM.updateFollowedStreamers(id: auth.user!.id, token: token) : streamerListVM.updateTopStreamers(token: token)
                    }, label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    })
                }
            }
            .onChange(of: auth.user) { value in
                auth.isLoggedIn ? streamerListVM.updateFollowedStreamers(id: auth.user!.id, token: token) : streamerListVM.updateTopStreamers(token: token)
            }
            .onAppear {
                if firstTime {
                    print("REFRESHING")
                    auth.isLoggedIn ? streamerListVM.updateFollowedStreamers(id: auth.user!.id, token: token) : streamerListVM.updateTopStreamers(token: token)
                    firstTime.toggle()
                }
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
