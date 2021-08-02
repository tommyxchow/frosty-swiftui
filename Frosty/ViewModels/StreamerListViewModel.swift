//
//  StreamerListViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

class StreamerListViewModel: ObservableObject {
    @Published var streamers: [StreamerInfo] = []
    @Published var search = ""
    let decoder = JSONDecoder()
    var filteredStreamers: [StreamerInfo] {
        if search.isEmpty {
            return streamers
        } else {
            return streamers.filter { $0.userLogin.contains(search.lowercased()) }
        }
    }
    
    func update(auth: Authentication) async {
        if let token = auth.userToken {
            auth.isLoggedIn ? await updateFollowedStreamers(id: auth.user!.id, token: token) : await updateTopStreamers(token: token)
        } else {
            await auth.getDefaultToken()
        }
    }
    
    func updateFollowedStreamers(id: String, token: String) async {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        if let data = await Request.perform(.GET, to: URL(string: "https://api.twitch.tv/helix/streams/followed?user_id=\(id)")!, headers: headers) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let result = try? decoder.decode(StreamerData.self, from: data) {
                streamers = result.data
                loadThumbnails()
            } else {
                print("Failed to parse followed streamers.")
            }
        }
    }
    
    func updateTopStreamers(token: String) async {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        if let data = await Request.perform(.GET, to: URL(string: "https://api.twitch.tv/helix/streams?first=50")!, headers: headers) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let result = try decoder.decode(StreamerData.self, from: data)
                streamers = result.data
                loadThumbnails()
            } catch {
                print("Failed to parse top streamers.")
            }
        }
    }
    
    func loadThumbnails() {
        for i in streamers.indices {
            let url = streamers[i].thumbnailUrl.replacingOccurrences(of: "-{width}x{height}", with: "-1280x720")
            streamers[i].thumbnailUrl = url
        }
    }
}
