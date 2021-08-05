//
//  StreamerListView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct StreamerListView: View {
    @EnvironmentObject private var auth: Authentication
    @StateObject private var viewModel = StreamerListViewModel()
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                ForEach(viewModel.filteredStreamers, id: \.userName) { streamer in
                    NavigationLink(destination: VideoChatView(streamer: streamer)) {
                        StreamerCardView(streamer: streamer)
                    }
                }
                .listRowSeparator(.hidden)
                if viewModel.loaded, viewModel.cursor != nil, viewModel.search.isEmpty {
                    ProgressView()
                        .task {
                            await viewModel.getMoreStreamers(token: auth.userToken!, type: viewModel.currentlyDisplaying)
                        }
                }
                if viewModel.filteredStreamers.isEmpty {
                    ForEach(viewModel.searchedStreamers, id:\.userName) { streamer in
                        NavigationLink(destination: VideoChatView(streamer: streamer)) {
                            StreamerCardView(streamer: streamer)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.grouped)
            .navigationTitle(viewModel.navigationTitle)
            .searchable(text: $viewModel.search, prompt: "Search")
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .refreshable {
                await viewModel.update(auth: auth)
            }
            .task {
                await viewModel.update(auth: auth)
            }
            .onChange(of: auth.user) { value in
                Task {
                    await viewModel.update(auth: auth)
                }
            }
            .onChange(of: viewModel.search) { newValue in
                if newValue.isEmpty {
                    viewModel.searchedStreamers.removeAll()
                }
            }
            .onSubmit(of: .search) {
                Task {
                    print("finding streamers")
                    let streamers = await viewModel.getStreamer(login: viewModel.search, token: auth.userToken!)
                    viewModel.searchedStreamers = streamers
                    print(streamers)
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
