//
//  StreamerListViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

class StreamerListViewModel: ObservableObject {
    @Published var streamers = [StreamerInfo]()
    @Published var searchedStreamers = [StreamerInfo]()
    @Published var search = ""
    @Published var currentlyDisplaying: StreamType = .top
    @Published var alertIsPresented = false
    
    private let decoder = JSONDecoder()
    
    var loaded = false
    var cursor: String?
    var navigationTitle: String {
        switch currentlyDisplaying {
        case .top:
            return "Top"
        case .followed:
            return "Followed"
        }
    }
    var filteredStreamers: [StreamerInfo] {
        if search.isEmpty {
            return streamers
        } else {
            return streamers.filter { $0.userLogin.contains(search.lowercased()) }
        }
    }
    
    func update(auth: Authentication) async {
        if let token = auth.userToken {
            print("Token already got")
            switch currentlyDisplaying {
            case .top:
                await updateTopStreamers(token: token)
            case .followed(let id):
                await updateFollowedStreamers(id: id, token: token)
            }
        } else {
            print("Getting default token")
            await auth.getDefaultToken()
            await updateTopStreamers(token: auth.userToken!)
        }
        loaded = true
    }
    
    func updateFollowedStreamers(id: String, token: String) async {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        let url = "https://api.twitch.tv/helix/streams/followed?first=10&user_id=\(id)"
        if let data = await Request.perform(.GET, to: URL(string: url)!, headers: headers) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let result = try decoder.decode(StreamerData.self, from: data)
                streamers = result.data
                cursor = result.pagination.cursor
            } catch {
                print("Failed to parse followed streamers.")
            }
        }
    }
    
    func updateTopStreamers(token: String) async {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        let url = "https://api.twitch.tv/helix/streams?first=10"
        
        if let data = await Request.perform(.GET, to: URL(string: url)!, headers: headers) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase
                        
            do {
                let result = try decoder.decode(StreamerData.self, from: data)
                streamers = result.data
                cursor = result.pagination.cursor
            } catch {
                print("Failed to parse top streamers.")
            }
        }
    }
    
    func getMoreStreamers(token: String, type: StreamType) async {
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
                let result = try decoder.decode(StreamerData.self, from: data)
                streamers.append(contentsOf: result.data)
                if let newCursor = result.pagination.cursor {
                    cursor = newCursor
                } else {
                    cursor = nil
                }
            } catch {
                print("Failed to parse top streamers.")
            }
        }
    }
    
    func getStreamer(login: String, token: String) async -> [StreamerInfo] {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        if let data = await Request.perform(.GET, to: URL(string: "https://api.twitch.tv/helix/streams?user_login=\(login)")!, headers: headers) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let result = try decoder.decode(StreamerData.self, from: data)
                return result.data
            } catch {
                print("Failed to parse top streamers.")
            }
        }
        return []
    }
}

enum StreamType {
    case top
    case followed(id: String)
}
