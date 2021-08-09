//
//  ChannelListView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

// TODO: Add keyboard shortcut that navigates to the searched channel on enter

struct ChannelListView: View {
    @EnvironmentObject private var auth: Authentication
    @StateObject private var viewModel = ChannelListViewModel()

    var body: some View {
        ScrollViewReader { _ in
            List {
                Group {
                    ForEach(viewModel.filteredChannels, id: \.userName) { channel in
                        NavigationLink(destination: VideoChatView(channelName: channel.userName)) {
                            ChannelCardView(channel: channel)
                        }
                    }
                    if viewModel.loaded, viewModel.cursor != nil, viewModel.search.isEmpty {
                        ProgressView()
                            .task {
                                await viewModel.getMoreChannels(
                                    token: auth.userToken!,
                                    type: viewModel.currentlyDisplaying
                                )
                            }
                    }
                    if viewModel.filteredChannels.isEmpty {
                        if viewModel.loaded, viewModel.searchedChannels.isEmpty {
                            NavigationLink(destination: VideoChatView(channelName: viewModel.search)) {
                                Text("Go to \(viewModel.search)")
                            }
                        } else {
                            ForEach(viewModel.searchedChannels, id: \.userName) { channel in
                                NavigationLink(destination: VideoChatView(channelName: channel.userName)) {
                                    ChannelCardView(channel: channel)
                                }
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.inset)
            .navigationTitle(viewModel.navigationTitle)
            .animation(.default, value: viewModel.channels)
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
                    viewModel.searchedChannels.removeAll()
                }
            }
            .onChange(of: viewModel.currentlyDisplaying) { _ in
                Task {
                    await viewModel.update(auth: auth)
                }
            }
            .onSubmit(of: .search) {
                Task {
                    let channel = await viewModel.getChannel(login: viewModel.search, token: auth.userToken!)
                    viewModel.searchedChannels = channel
                    print(channel)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Picker("Category", selection: $viewModel.currentlyDisplaying) {
                        Text("Top").tag(Category.top)
                        if let user = auth.user {
                            Text("Followed").tag(Category.followed(id: user.id))
                        }
                        Text("Categories")
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

struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChannelListView()
                .environmentObject(Authentication())
        }
    }
}
