//
//  StreamerListViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

class StreamerListViewModel: ObservableObject {
    @Published var streamers: [StreamerInfo] = []
    
    func updateFollowedStreamers(id: String, token: String) {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        Request.perform(.GET, to: URL(string: "https://api.twitch.tv/helix/streams/followed?user_id=\(id)")!, headers: headers) { data in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let result = try? decoder.decode(StreamerData.self, from: data) {
                DispatchQueue.main.async {
                    self.streamers = result.data
                    self.loadThumbnails()
                }
            } else {
                print("Failed to parse followed streamers.")
            }
        }
    }
    
    func updateTopStreamers(token: String) {
        let headers = ["Authorization": "Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        Request.perform(.GET, to: URL(string: "https://api.twitch.tv/helix/streams")!, headers: headers) { data in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let result = try? decoder.decode(StreamerData.self, from: data) {
                DispatchQueue.main.async {
                    self.streamers = result.data
                    self.loadThumbnails()
                }
            } else {
                print("Failed to parse top streamers.")
            }
        }
    }
    
    func loadThumbnails() {        
        for i in streamers.indices {
            let url = streamers[i].thumbnailUrl.replacingOccurrences(of: "-{width}x{height}", with: "")
            Request.perform(.GET, to: URL(string: url)!) { data in
                DispatchQueue.main.async {
                    self.streamers[i].thumbnail = data
                }
            }
        }
    }
}
