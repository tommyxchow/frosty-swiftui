//
//  CacheManager.swift
//  Frosty
//
//  Created by Tommy Chow on 6/19/21.
//

import Foundation

// TODO: Some channels might have identical BTTV/FFZ channel emotes, figure out a way to reuse those instead of caching individual folders per user

struct CacheManager {
    static private let fileManager = FileManager.default
    static private let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    static let cache = NSCache<NSString, NSData>()
    static private let decoder = JSONDecoder()
    static let defaults = UserDefaults.standard
    
    static func cacheContents(requestedDataType: APIData, token: String? = nil, registryId: String) async throws {
        let folder: URL
        
        switch requestedDataType {
        case .emoteTwitchGlobal:
            folder = cachesDirectory.appendingPathComponent("TwitchAssets/Global")
        case .emoteTwitchChannel(let id):
            folder = cachesDirectory.appendingPathComponent("TwitchAssets").appendingPathComponent(id)
        case .emoteBTTVGlobal:
            folder = cachesDirectory.appendingPathComponent("BTTVAssets/Global")
        case .emoteBTTVChannel(let id):
            folder = cachesDirectory.appendingPathComponent("BTTVAssets").appendingPathComponent(id)
        case .emoteFFZGlobal:
            folder = cachesDirectory.appendingPathComponent("FFZAssets/Global")
        case .emoteFFZChannel(let id):
            folder = cachesDirectory.appendingPathComponent("FFZAssets").appendingPathComponent(id)
        case .badgeTwitchGlobal:
            folder = cachesDirectory.appendingPathComponent("TwitchAssets/Global")
        case .badgeTwitchChannel(let id):
            folder = cachesDirectory.appendingPathComponent("TwitchAssets").appendingPathComponent(id)
        }
        
        //print(folder)
        
        if let registry = defaults.object(forKey: registryId) as? [String:String] {
            print("Registry already exists for \(requestedDataType)")
            // print(emoteRegistry)
            for item in registry {
                let itemPath = folder.appendingPathComponent(item.value)
                let itemData = try Data(contentsOf: itemPath)
                cache.setObject(NSData(data: itemData), forKey: NSString(string: item.key))
            }
        } else if let data = await getAPIData(type: requestedDataType, token: token) {
            let registry = try await writeToFolderAndCache(type: requestedDataType, data: data, folder: folder)
            defaults.set(registry, forKey: registryId)
        } else {
            print("Caching failed!")
        }
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
    
    static func writeToFolderAndCache(type: APIData, data: Data, folder: URL) async throws -> [String:String] {
        var registry: [String:String] = [:]
        
        switch type {
        case .emoteTwitchGlobal, .emoteTwitchChannel:
            let result = try decoder.decode(EmoteDataTwitch.self, from: data)
            for emote in result.data {
                if let emoteData = await Request.perform(.GET, to: URL(string: emote.images.url_1x)!)  {
                    writeAndCache(folder: folder, data: emoteData, cacheName: emote.name, fileName: emote.id + ".png")
                } else {
                    print("Twitch emote request failed")
                }
                registry[emote.name] = emote.id + ".png"
            }
            print("Cached Twitch emotes")
        case .emoteBTTVGlobal:
            let result = try decoder.decode([EmoteBTTVGlobal].self, from: data)
            for emote in result {
                if let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!) {
                    writeAndCache(folder: folder, data: emoteData, cacheName: emote.code, fileName: "\(emote.id).\(emote.imageType)")
                } else {
                    print("BTTV global emote request failed")
                }
                registry[emote.code] = "\(emote.id).\(emote.imageType)"
            }
            print("Cached BTTV global emotes")
        case .emoteBTTVChannel:
            let result = try decoder.decode(EmoteBTTVChannel.self, from: data)
            for emote in result.channelEmotes {
                if let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!) {
                    writeAndCache(folder: folder, data: emoteData, cacheName: emote.code, fileName: "\(emote.id).\(emote.imageType)")
                } else {
                    print("BTTV channel emote request failed")
                }
                registry[emote.code] = "\(emote.id).\(emote.imageType)"
            }
            for emote in result.sharedEmotes {
                if let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!) {
                    writeAndCache(folder: folder, data: emoteData, cacheName: emote.code, fileName: "\(emote.id).\(emote.imageType)")
                } else {
                    print("BTTV shared emote request failed")
                }
                registry[emote.code] = "\(emote.id).\(emote.imageType)"
            }
            print("Cached BTTV channel emotes")
        case .emoteFFZGlobal, .emoteFFZChannel:
            let result = try decoder.decode([EmotesFFZ].self, from: data)
            for emote in result {
                if let emoteData = await Request.perform(.GET, to: URL(string: emote.images.emote1x)!) {
                    writeAndCache(folder: folder, data: emoteData, cacheName: emote.code, fileName: "\(emote.id).\(emote.imageType)")
                } else {
                    print("FFZ emote request failed")
                }
                registry[emote.code] = "\(emote.id).\(emote.imageType)"
            }
            print("Cached FFZ emotes")
        case .badgeTwitchGlobal, .badgeTwitchChannel:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let result = try decoder.decode(BadgeData.self, from: data)
            for badge in result.data {
                
                for badgeVersion in badge.versions {
                    if let badgeData = await Request.perform(.GET, to: URL(string: badgeVersion.imageUrl1X)!) {
                        writeAndCache(folder: folder, data: badgeData, cacheName: "\(badge.setId)/\(badgeVersion.id)", fileName: "\(badge.setId)@\(badgeVersion.id).png")
                    }
                    registry["\(badge.setId)/\(badgeVersion.id)"] = "\(badge.setId)@\(badgeVersion.id).png"
                }
            }
            print("Cached Twitch badges")
        }
        return registry
    }
    
    private static func writeAndCache(folder: URL, data: Data, cacheName: String, fileName: String) {
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            let filePath = folder.appendingPathComponent(fileName)
            try data.write(to: filePath, options: .atomic)
            
            cache.setObject(NSData(data: data), forKey: NSString(string: cacheName))
        } catch {
            print("Failed to write and cache")
        }
    }
    
    static func clearCache() {
        let folders = ["TwitchAssets", "BTTVAssets", "FFZAssets"]
        for folder in folders {
            let path = cachesDirectory.appendingPathComponent(folder)
            do {
                try fileManager.removeItem(at: path)
            } catch {
                print("Folder does not exist")
            }
        }
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        cache.removeAllObjects()
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
