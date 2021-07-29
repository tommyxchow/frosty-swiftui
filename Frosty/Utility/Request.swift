//
//  Request.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

struct Request {
    static private let session = URLSession.shared
    static let decoder = JSONDecoder()
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
    }
    
    static func perform(_ method: HTTPMethod, to url: URL, headers: [String:String]? = nil) async -> Data? {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
                        
        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
                
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("ERROR: NON 200-LEVEL RESPONSE")
                return nil
            }
            
            return data
        } catch {
            print("Request failed to \(url)")
            return nil
        }
    }
    
    static func assetToUrl(requestedDataType: APIData, token: String? = nil) async throws -> [String:URL] {
        var registry: [String:URL] = [:]
        
        guard let data = await getAPIData(type: requestedDataType, token: token) else {
            print("Failed to get API data for \(requestedDataType) :(")
            return registry
        }
        
        switch requestedDataType {
        case .emoteTwitchGlobal, .emoteTwitchChannel:
            let result = try decoder.decode(EmoteDataTwitch.self, from: data)
            for emote in result.data {
                registry[emote.name] = URL(string: emote.images.url_1x)!
            }
            print("Cached Twitch emotes")
        case .emoteBTTVGlobal:
            let result = try decoder.decode([EmoteBTTVGlobal].self, from: data)
            for emote in result {
                registry[emote.code] = URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!
            }
            print("Cached BTTV global emotes")
        case .emoteBTTVChannel:
            let result = try decoder.decode(EmoteBTTVChannel.self, from: data)
            for emote in result.channelEmotes {
                registry[emote.code] = URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!
            }
            for emote in result.sharedEmotes {
                registry[emote.code] = URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!
            }
            print("Cached BTTV channel emotes")
        case .emoteFFZGlobal, .emoteFFZChannel:
            let result = try decoder.decode([EmotesFFZ].self, from: data)
            for emote in result {
                registry[emote.code] = URL(string: emote.images.emote1x)!
            }
            print("Cached FFZ emotes")
        case .badgeTwitchGlobal, .badgeTwitchChannel:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let result = try decoder.decode(BadgeData.self, from: data)
            for badge in result.data {
                for badgeVersion in badge.versions {
                    registry["\(badge.setId)/\(badgeVersion.id)"] = URL(string: badgeVersion.imageUrl1X)!
                }
            }
            print("Cached Twitch badges")
        }
        return registry
    }
    
    static func getAPIData(type: APIData, token: String? = nil) async -> Data? {
        let endpoint: URL
        let headers: [String:String]?
        
        switch type {
        case .emoteTwitchGlobal:
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/emotes/global")!
            headers = ["Authorization":"Bearer \(token!)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        case .emoteTwitchChannel(let id):
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/emotes?broadcaster_id=\(id)")!
            headers = ["Authorization":"Bearer \(token!)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        case .emoteBTTVGlobal:
            endpoint = URL(string: "https://api.betterttv.net/3/cached/emotes/global")!
            headers = nil
        case .emoteBTTVChannel(let id):
            endpoint = URL(string: "https://api.betterttv.net/3/cached/users/twitch/\(id)")!
            headers = nil
        case .emoteFFZGlobal:
            endpoint = URL(string: "https://api.betterttv.net/3/cached/frankerfacez/emotes/global")!
            headers = nil
        case .emoteFFZChannel(let id):
            endpoint = URL(string: "https://api.betterttv.net/3/cached/frankerfacez/users/twitch/\(id)")!
            headers = nil
        case .badgeTwitchGlobal:
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/badges/global")!
            headers = ["Authorization":"Bearer \(token!)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        case .badgeTwitchChannel(let id):
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/badges?broadcaster_id=\(id)")!
            headers = ["Authorization":"Bearer \(token!)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        }
        
        if let data = await Request.perform(.GET, to: endpoint, headers: headers) {
            return data
        } else {
            return nil
        }
        
    }
}

enum APIData {
    case emoteTwitchGlobal
    case emoteTwitchChannel(id: String)
    case emoteBTTVGlobal
    case emoteBTTVChannel(id: String)
    case emoteFFZGlobal
    case emoteFFZChannel(id: String)
    case badgeTwitchGlobal
    case badgeTwitchChannel(id: String)
}
