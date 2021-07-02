//
//  Cache.swift
//  Frosty
//
//  Created by Tommy Chow on 6/19/21.
//

import Foundation

// TODO: Some channels might have identical BTTV/FFZ channel emotes, figure out a way to reuse those instead of caching individual folders per user

struct Cache {
    static private let fileManager = FileManager.default
    static private let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent(Bundle.main.bundleIdentifier!)
    static let cache = NSCache<NSString, NSData>()
    static private let decoder = JSONDecoder()
    static let defaults = UserDefaults.standard
    
    static func cacheContents(type: Category, token: String? = nil, id: String) async throws -> [String:String] {
        let folder: URL
        let requestedDataType: APIData
        
        switch type {
        case .twitch(let dataType):
            folder = cachesDirectory.appendingPathComponent("TwitchAssets")
            requestedDataType = dataType
        case .bttv(let dataType):
            folder = cachesDirectory.appendingPathComponent("BTTVAssets")
            requestedDataType = dataType
        case .ffz(let dataType):
            folder = cachesDirectory.appendingPathComponent("FFZAssets")
            requestedDataType = dataType
        }
        
        //print(folder)
        
        var emoteToId: [String:String] = [:]
        if let emoteRegistry = defaults.object(forKey: id) as? [String:String] {
            print("Registry already exists for \(requestedDataType)")
            // print(emoteRegistry)
            for emoteInfo in emoteRegistry {
                let emotePath = folder.appendingPathComponent("\(emoteInfo.value).png")
                let emoteData = try Data(contentsOf: emotePath)
                cache.setObject(NSData(data: emoteData), forKey: NSString(string: emoteInfo.key))
            }
            emoteToId = emoteRegistry
        } else if let data = await getAPIData(type: requestedDataType, token: token) {
            let registry = try await writeToFolderAndCache(type: requestedDataType, data: data, folder: folder)
            defaults.set(registry, forKey: id)
            emoteToId = registry
        } else {
            print("Caching failed!")
        }
        return emoteToId
    }
    
    static func getAPIData(type: APIData, token: String? = nil) async -> Data? {
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
    
    static func writeToFolderAndCache(type: APIData, data: Data, folder: URL) async throws -> [String:String] {
        var registry: [String:String] = [:]
        
        switch type {
        case .emoteTwitchGlobal, .emoteTwitchChannel:
            let result = try decoder.decode(EmoteDataTwitch.self, from: data)
            for emote in result.data {
                if let emoteData = await Request.perform(.GET, to: URL(string: emote.images.url_1x)!)  {
                    writeAndCache(folder: folder, data: emoteData, name: emote.name, id: emote.id)
                } else {
                    print("Twitch emote request failed")
                }
                registry[emote.name] = emote.id
            }
            print(1)
        case .emoteBTTVGlobal:
            let result = try decoder.decode([EmoteBTTVGlobal].self, from: data)
            for emote in result {
                if let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!) {
                    writeAndCache(folder: folder, data: emoteData, name: emote.code, id: emote.id)
                } else {
                    print("BTTV global emote request failed")
                }
                registry[emote.code] = emote.id
            }
            print(2)
        case .emoteBTTVChannel:
            let result = try decoder.decode(EmoteBTTVChannel.self, from: data)
            for emote in result.channelEmotes {
                if let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!) {
                    writeAndCache(folder: folder, data: emoteData, name: emote.code, id: emote.id)
                } else {
                    print("BTTV channel emote request failed")
                }
                registry[emote.code] = emote.id
            }
            for emote in result.sharedEmotes {
                if let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!) {
                    writeAndCache(folder: folder, data: emoteData, name: emote.code, id: emote.id)
                } else {
                    print("BTTV shared emote request failed")
                }
                registry[emote.code] = emote.id
            }
            print(3)
        case .emoteFFZGlobal, .emoteFFZChannel:
            let result = try decoder.decode([EmotesFFZ].self, from: data)
            for emote in result {
                if let emoteData = await Request.perform(.GET, to: URL(string: emote.images.emote1x)!) {
                    writeAndCache(folder: folder, data: emoteData, name: emote.code, id: String(emote.id))
                } else {
                    print("FFZ emote request failed")
                }
                registry[emote.code] = String(emote.id)
            }
            print(4)
        case .badgeTwitchGlobal:
            break
        case .badgeTwitchChannel:
            break
        }
        return registry
    }
    
    private static func writeAndCache(folder: URL, data: Data, name: String, id: String) {
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            let filePath = folder.appendingPathComponent("\(id).png")
            try data.write(to: filePath, options: .atomic)
            
            cache.setObject(NSData(data: data), forKey: NSString(string: name))
        } catch {
            print("Failed to write and cache")
        }
    }
}

enum Category {
    case twitch(dataType: APIData)
    case bttv(dataType: APIData)
    case ffz(dataType: APIData)
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
