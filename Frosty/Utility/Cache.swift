//
//  Cache.swift
//  Frosty
//
//  Created by Tommy Chow on 6/19/21.
//

import Foundation

// TODO: Some channels might have identical BTTV/FFZ channel emotes, figure out a way to reuse those instead of caching individual folders per user
// TODO: 
struct Cache {
    static private let fileManager = FileManager.default
    static private let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    static let cache = NSCache<NSString, NSData>()
    static private let decoder = JSONDecoder()
    static let defaults = UserDefaults.standard
    
    static func cacheContents(type: APIData, token: String? = nil) async throws -> Bool {
        let folder: URL
        
        switch type {
        case .emoteTwitchGlobal:
            folder = cachesDirectory.appendingPathComponent("TwitchGlobalAssets")
        case .emoteTwitchChannel(let id):
            folder = cachesDirectory.appendingPathComponent("TwitchChannelAssets/\(id)")
        case .emoteBTTVGlobal:
            folder = cachesDirectory.appendingPathComponent("BTTVGlobalEmotes")
        case .emoteBTTVChannel(let id):
            folder = cachesDirectory.appendingPathComponent("BTTVChannelAssets/\(id)")
        case .emoteFFZGlobal:
            folder = cachesDirectory.appendingPathComponent("FFZGlobalEmotes")
        case .emoteFFZChannel(let id):
            folder = cachesDirectory.appendingPathComponent("FFZChannelAssets/\(id)")
        case .badgeTwitchGlobal:
            folder = cachesDirectory.appendingPathComponent("TwitchGlobalAssets")
        case .badgeTwitchChannel(let id):
            folder = cachesDirectory.appendingPathComponent("TwitchChannelAssets/\(id)")
        }
        
        if fileManager.fileExists(atPath: folder.path) {
            print("folder already exists")
            let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
            for emote in contents {
                let emotePath = folder.appendingPathComponent(emote)
                let emoteData = try Data(contentsOf: emotePath)
                cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote))
            }
        } else if let data = await getAPIData(type, token: token) {
            try await writeToCacheFolder(type, data: data, folder: folder)
            defaults.set(ChatManager.emoteToId, forKey: "emoteRegistry")
        } else {
            print("Caching failed!")
        }
        return true
    }
    
    static func getAPIData(_ type: APIData, token: String? = nil) async -> Data? {
        let endpoint: URL
        let headers: [String:String]?
        
        switch type {
        case .emoteTwitchGlobal:
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/emotes?broadcaster_id=0")!
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
            endpoint = URL(string: "https://api.betterttv.net/3/cached/emotes/global")!
            headers = ["Authorization":"Bearer \(token!)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        case .badgeTwitchChannel:
            endpoint = URL(string: "https://api.twitch.tv/helix/chat/badges/global")!
            headers = ["Authorization":"Bearer \(token!)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi"]
        }
        
        if let data = await Request.perform(.GET, to: endpoint, headers: headers) {
            return data
        } else {
            return nil
        }
        
    }
    
    private static func writeAndCache(folder: URL, data: Data, name: String, id: String) {
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            let filePath = folder.appendingPathComponent("\(id).png")
            try data.write(to: filePath, options: .atomic)
            
            Cache.cache.setObject(NSData(data: data), forKey: NSString(string: "\(id).png"))
            
            ChatManager.emoteToId[name] = id
        } catch {
            print("Failed to write and cache")
        }
    }
        
    
    static func writeToCacheFolder(_ type: APIData, data: Data, folder: URL) async throws {
        switch type {
        case .emoteTwitchGlobal:
            let result = try decoder.decode(EmoteDataTwitch.self, from: data)
            for emote in result.data {
                let emoteData = await Request.perform(.GET, to: URL(string: emote.images.url_1x)!)
                if let emoteData = emoteData {
                    writeAndCache(folder: folder, data: emoteData, name: emote.name, id: emote.id)
                } else {
                    print("Twitch emote request failed")
                }
            }
            print(1)
        case .emoteTwitchChannel:
            let result = try decoder.decode(EmoteDataTwitch.self, from: data)
            for emote in result.data {
                if let emoteData = await Request.perform(.GET, to: URL(string: emote.images.url_1x)!)  {
                    writeAndCache(folder: folder, data: emoteData, name: emote.name, id: emote.id)
                } else {
                    print("Twitch channel emote request failed")
                }
            }
            print(2)
        case .emoteBTTVGlobal:
            let result = try decoder.decode([EmoteBTTV].self, from: data)
            for emote in result {
                let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                if let emoteData = emoteData {
                    writeAndCache(folder: folder, data: emoteData, name: emote.code, id: emote.id)
                } else {
                    print("BTTV GLOBAL FAILED")
                }
            }
            print(3)
        case .emoteBTTVChannel:
            let result = try decoder.decode(ChannelEmotesBTTV.self, from: data)
            for emote in result.channelEmotes {
                let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                if let emoteData = emoteData {
                    writeAndCache(folder: folder, data: emoteData, name: emote.code, id: emote.id)
                } else {
                    print("BTTV CHANNEL EMOTE FAILED")
                }
            }
            for emote in result.sharedEmotes {
                let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                if let emoteData = emoteData {
                    writeAndCache(folder: folder, data: emoteData, name: emote.code, id: emote.id)
                } else {
                    print("BTTV SHARED EMOTE FAILED")
                }
            }
            print(4)
        case .emoteFFZGlobal:
            let result = try decoder.decode([EmotesFFZ].self, from: data)
            for emote in result {
                let emoteData = await Request.perform(.GET, to: URL(string: emote.images.emote1x)!)
                if let emoteData = emoteData {
                    writeAndCache(folder: folder, data: emoteData, name: emote.code, id: String(emote.id))
                } else {
                    print("FFZ GLOBAL EMOTE FAILED")
                }
            }
            print(5)
        case .emoteFFZChannel:
            let result = try decoder.decode([EmotesFFZ].self, from: data)
            for emote in result {
                let emoteData = await Request.perform(.GET, to: URL(string: emote.images.emote1x)!)
                if let emoteData = emoteData {
                    writeAndCache(folder: folder, data: emoteData, name: emote.code, id: String(emote.id))
                } else {
                    print("FFZ CHANNEL EMOTE FAILED")
                }
            }
            print(6)
        case .badgeTwitchGlobal:
            return
        case .badgeTwitchChannel:
            return
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
