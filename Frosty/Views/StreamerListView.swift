//
//  StreamerListView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

// TODO: Add keyboard shortcut that navigates to the searched channel on enter

struct StreamerListView: View {
    @EnvironmentObject private var auth: Authentication
    @StateObject private var viewModel = StreamerListViewModel()
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                Group {
                    ForEach(viewModel.filteredStreamers, id: \.userName) { streamer in
                        NavigationLink(destination: VideoChatView(channelName: streamer.userName)) {
                            StreamerCardView(streamer: streamer)
                        }
                    }
                    if viewModel.loaded, viewModel.cursor != nil, viewModel.search.isEmpty {
                        ProgressView()
                            .task {
                                await viewModel.getMoreStreamers(token: auth.userToken!, type: viewModel.currentlyDisplaying)
                            }
                    }
                    if viewModel.filteredStreamers.isEmpty {
                        if viewModel.loaded, viewModel.searchedStreamers.isEmpty {
                            NavigationLink(destination: VideoChatView(channelName: viewModel.search)) {
                                Text("Go to \(viewModel.search)")
                            }
                        } else {
                            ForEach(viewModel.searchedStreamers, id:\.userName) { streamer in
                                NavigationLink(destination: VideoChatView(channelName: streamer.userName)) {
                                    StreamerCardView(streamer: streamer)
                                }
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.inset)
            .navigationTitle(viewModel.navigationTitle)
            .animation(.default, value: viewModel.streamers)
            .searchable(text: $viewModel.search, placement: .navigationBarDrawer(displayMode: .always))
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .refreshable {
                await viewModel.update(auth: auth)
            }
            .task {
                await viewModel.update(auth: auth)
            }
            .onChange(of: viewModel.search) { newValue in
                if newValue.isEmpty {
                    viewModel.searchedStreamers.removeAll()
                }
            }
            .onChange(of: viewModel.currentlyDisplaying) { newValue in
                Task {
                    await viewModel.update(auth: auth)
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
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Picker("Category", selection: $viewModel.currentlyDisplaying) {
                        Text("Top").tag(Category.top)
                        if let user = auth.user {
                            Text("Followed").tag(Category.followed(id: user.id))
                        }
                        Text("Games")
                    }
                    .pickerStyle(.segmented)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape")
                    }
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
