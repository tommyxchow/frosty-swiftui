//
//  StreamerListViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

class StreamerListViewModel: ObservableObject {
    @Published var streamers: [StreamerInfo] = []
    private let decoder = JSONDecoder()
    var loaded = false
    var cursor: String?
    
    func update(auth: Authentication) async {
        if let token = auth.userToken {
            auth.isLoggedIn ? await updateFollowedStreamers(id: auth.user!.id, token: token) : await updateTopStreamers(token: token)
        } else {
            await auth.getDefaultToken()
        }
        loaded = true
    }
    
    func updateFollowedStreamers(id: String, token: String) async {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        let url = "https://api.twitch.tv/helix/streams/followed?user_id=\(id)"
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
        let url = "https://api.twitch.tv/helix/streams"
        
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
    
    func getMoreStreamers(token: String) async {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]

        let url = "https://api.twitch.tv/helix/streams?after=\(cursor!)"
        
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
