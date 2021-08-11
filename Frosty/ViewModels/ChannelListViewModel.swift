//
//  ChannelListViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

// TODO: Add recently searched channels as suggestions when searching.

class ChannelListViewModel: ObservableObject {
    @Published var channels = [Channel]()
    @Published var searchedChannels = [Channel]()
    @Published var search = ""
    @Published var currentlyDisplaying = Category.top
    @Published var alertIsPresented = false

    private let decoder = JSONDecoder()

    var loaded = false
    var cursor: String?
    var navigationTitle: String {
        switch currentlyDisplaying {
        case .top:
            return "Top Channels"
        case .followed:
            return "Followed Channels"
        }
    }
    var filteredChannels: [Channel] {
        if search.isEmpty {
            return channels
        } else {
            return channels.filter { $0.userLogin.contains(search.lowercased()) }
        }
    }

    /// Update the list of channels depending on which category is currently being shown.
    func update(auth: Authentication) async {
        if let token = auth.userToken {
            print("Token already got")
            switch currentlyDisplaying {
            case .top:
                await updateTopChannels(token: token)
            case .followed(let id):
                await updateFollowedChannels(id: id, token: token)
            }
        } else {
            print("Getting default token")
            await auth.getDefaultToken()
            await updateTopChannels(token: auth.userToken!)
        }
        loaded = true
    }

    @MainActor func updateFollowedChannels(id: String, token: String) async {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        let url = "https://api.twitch.tv/helix/streams/followed?first=10&user_id=\(id)"
        if let data = await Request.perform(.GET, to: URL(string: url)!, headers: headers) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                let result = try decoder.decode(Channels.self, from: data)
                channels = result.data
                cursor = result.pagination.cursor
            } catch {
                print("Failed to parse followed channels.")
            }
        }
    }

    @MainActor func updateTopChannels(token: String) async {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        let url = "https://api.twitch.tv/helix/streams?first=10"

        if let data = await Request.perform(.GET, to: URL(string: url)!, headers: headers) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                let result = try decoder.decode(Channels.self, from: data)
                channels = result.data
                cursor = result.pagination.cursor
            } catch {
                print("Failed to parse top channels.")
            }
        }
    }

    /// Retrieve more channels using pagination.
    func getMoreChannels(token: String, type: Category) async {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]

        let url: String

        switch type {
        case .top:
            url = "https://api.twitch.tv/helix/streams?first=10&after=\(cursor!)"
        case .followed(let id):
            url = "https://api.twitch.tv/helix/streams/followed?user_id=\(id)&first=10&after=\(cursor!)"
        }

        if let data = await Request.perform(.GET, to: URL(string: url)!, headers: headers) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                let result = try decoder.decode(Channels.self, from: data)
                channels.append(contentsOf: result.data)
                if let newCursor = result.pagination.cursor {
                    cursor = newCursor
                } else {
                    cursor = nil
                }
            } catch {
                print("Failed to parse top channels.")
            }
        }
    }

    /// Retrieve a single channel.
    func getChannel(login: String, token: String) async -> [Channel] {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        if let data = await Request.perform(.GET, to: URL(string: "https://api.twitch.tv/helix/streams?user_login=\(login)")!, headers: headers) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                let result = try decoder.decode(Channels.self, from: data)
                return result.data
            } catch {
                print("Failed to parse top channels.")
            }
        }
        return []
    }
}

enum Category: Hashable {
    case top
    case followed(id: String)
}
