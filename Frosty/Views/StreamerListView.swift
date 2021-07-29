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
        List(streamerListVM.streamers, id: \.userName) { streamer in
            NavigationLink(destination: VideoChatView(streamer: streamer)) {
                StreamerCardView(streamer: streamer)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.grouped)
        .navigationTitle("Live")
        .task {
            if firstTime {
                await streamerListVM.update(auth: auth)
                firstTime = false
            }
        }
        .onChange(of: auth.user) { value in
            Task {
                await streamerListVM.update(auth: auth)
            }
        }
        .refreshable {
            await streamerListVM.update(auth: auth)
        }
        .searchable(text: $streamerListVM.search) {
            List {
                ForEach(streamerListVM.filteredStreamers, id: \.userName) { streamer in
                    Text(streamer.userName)
                }
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
