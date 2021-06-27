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

    
    static func cacheContentsIn(directory: Directory) throws {
        let folder: URL
        
        switch directory {
        case .globalTwitch:
            folder = cachesDirectory.appendingPathComponent("TwitchGlobalEmotes")
        case .channelTwitch:
            folder = cachesDirectory.appendingPathComponent("TwitchChannelAssets")
        case .globalBTTV:
            folder = cachesDirectory.appendingPathComponent("BTTVGlobalEmotes")
        case .channelBTTV:
            folder = cachesDirectory.appendingPathComponent("BTTVChannelAssets")
        case .globalFFZ:
            folder = cachesDirectory.appendingPathComponent("FFZGlobalEmotes")
        case .channelFFZ:
            folder = cachesDirectory.appendingPathComponent("FFZChannelAssets")
        }
        
        let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
        for emote in contents {
            let emotePath = folder.appendingPathComponent(emote)
            let emoteData = try Data(contentsOf: emotePath)
            cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote))
        }
    }
    
//    static func writeToCacheFolder(_ type: APIData, data: Data) throws {
//
//        switch type {
//        case .emoteTwitch:
//            let result = try decoder.decode(EmoteDataTwitch.self, from: data)
//        case .emoteBTTV:
//            <#code#>
//        case .emoteFFZ:
//            <#code#>
//        case .badge:
//            <#code#>
//        }
//
//    }
//
//    static func getEmoteData<T>(_ type: APIData, data: [T]) {
//        var result: [T]
//        switch type {
//        case .emoteTwitch:
//
//        case .emoteBTTV:
//            <#code#>
//        case .emoteFFZ:
//            <#code#>
//        case .badge:
//            <#code#>
//        }
//
//
//        for emote in data {
//        }
//    }
    
    static func validateCache() {
        
    }
}

enum APIData {
    case emoteTwitch
    case emoteBTTV
    case emoteFFZ
    case badge
}




enum Directory {
    case globalTwitch
    case channelTwitch
    case globalBTTV
    case channelBTTV
    case globalFFZ
    case channelFFZ
}
