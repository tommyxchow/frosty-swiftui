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
    @State private var search = ""
    
    var body: some View {
        List(streamerListVM.streamers, id: \.userName) { streamer in
            NavigationLink(destination: VideoChatView(streamer: streamer)) {
                StreamerCardView(streamer: streamer)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.grouped)
        .navigationTitle("Live")
        .task {
            await streamerListVM.update(auth: auth)
        }
        .onChange(of: auth.user) { value in
            async {
                await streamerListVM.update(auth: auth)
            }
        }
        .refreshable {
            await streamerListVM.update(auth: auth)
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
