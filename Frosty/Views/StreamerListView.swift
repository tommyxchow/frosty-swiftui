//
//  StreamerListView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct StreamerListView: View {
    @EnvironmentObject private var auth: Authentication
    @StateObject private var streamerListVM = StreamerListViewModel()
    @State private var search = ""
    @State private var searchedStreamers: [StreamerInfo] = []
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                ForEach(filteredStreamers, id: \.userName) { streamer in
                    NavigationLink(destination: VideoChatView(streamer: streamer)) {
                        StreamerCardView(streamer: streamer)
                    }
                    .listRowSeparator(.hidden)
                }
                if streamerListVM.loaded, streamerListVM.cursor != nil, search.isEmpty {
                    ProgressView()
                        .task {
                            await streamerListVM.getMoreStreamers(token: auth.userToken!)
                        }
                }
                if filteredStreamers.isEmpty {
                    ForEach(searchedStreamers, id:\.userName) { streamer in
                        NavigationLink(destination: VideoChatView(streamer: streamer)) {
                            StreamerCardView(streamer: streamer)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Live")
            .task {
                await streamerListVM.update(auth: auth)
            }
            .onChange(of: auth.user) { value in
                Task {
                    await streamerListVM.update(auth: auth)
                }
            }
            .refreshable {
                await streamerListVM.update(auth: auth)
            }
            .searchable(text: $search, prompt: "Search")
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .onSubmit(of: .search) {
                Task {
                    print("finding streamers")
                    let streamers = await streamerListVM.getStreamer(login: search, token: auth.userToken!)
                    searchedStreamers = streamers
                }
            }
            .onChange(of: search) { newValue in
                if newValue.isEmpty {
                    searchedStreamers.removeAll()
                }
            }
        }
    }
    
    var filteredStreamers: [StreamerInfo] {
        if search.isEmpty {
            return streamerListVM.streamers
        } else {
            return streamerListVM.streamers.filter { $0.userLogin.contains(search.lowercased()) }
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
