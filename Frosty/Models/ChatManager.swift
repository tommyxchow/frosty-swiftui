//
//  ChatManager.swift
//  Frosty
//
//  Created by Tommy Chow on 6/16/21.
//

import Foundation

struct ChatManager {
    static let fileManager = FileManager.default
    static private let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    static let cache = NSCache<NSString, NSData>()
    static private let decoder = JSONDecoder()
    
    static func clearCache() {
        let folders = ["TwitchGlobalEmotes1", "TwitchChannelEmotes", "BTTVGlobalEmotes1", "BTTVChannelEmotes", "FFZChannelEmotes"]
        for folder in folders {
            let path = cachesDirectory.appendingPathComponent(folder)
            do {
                try fileManager.removeItem(at: path)
            } catch {
                print("Folder does not exist")
            }
        }
        
    }
        
    static func getGlobalEmotesTwitch(token: String) async {
        let endpoint = URL(string: "https://api.twitch.tv/helix/chat/emotes/global")!
        let headers = ["Authorization":"Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi" ]
        let folder = cachesDirectory.appendingPathComponent("TwitchGlobalEmotes")
        print(folder)
        
        if fileManager.fileExists(atPath: folder.path) {
            print("Folder already exists")
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
                for emote in contents {
                    let emotePath = folder.appendingPathComponent(emote)
                    let emoteData = try Data(contentsOf: emotePath)
                    cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote))
                }
            } catch {
                print("Fail")
            }
        } else if let data = await Request.perform(.GET, to: endpoint, headers: headers) {
            do {
                let result = try decoder.decode(EmoteDataTwitch.self, from: data)
                for emote in result.data {
                    let emoteData = await Request.perform(.GET, to: URL(string: emote.images.url_1x)!)
                    if let emoteData = emoteData {
                        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.name + ".png"))
                        let filePath = folder.appendingPathComponent("\(emote.name).png")
                        fileManager.createFile(atPath: filePath.path, contents: emoteData)
                    } else {
                        print("Twitch emote request failed")
                    }
                }
            } catch {
                print("Failed to save global emote:", error.localizedDescription)
            }
        } else {
            print("Failed to get global emote data")
        }
    }
    
    static func getChannelEmotesTwitch(token: String, id: String) async {
        let endpoint = URL(string: "https://api.twitch.tv/helix/chat/emotes?broadcaster_id=\(id)")!
        let headers = ["Authorization":"Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi" ]
        let decoder = JSONDecoder()
        let folder = cachesDirectory.appendingPathComponent("TwitchChannelEmotes/\(id)")
        
        if fileManager.fileExists(atPath: folder.path) {
            print("Folder already exists")
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
                for emote in contents {
                    let emotePath = folder.appendingPathComponent(emote)
                    let emoteData = try Data(contentsOf: emotePath)
                    cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote))
                }
            } catch {
                print("Fail")
            }
        } else if let data = await Request.perform(.GET, to: endpoint, headers: headers) {
            do {
                let result = try decoder.decode(EmoteDataTwitch.self, from: data)
                for emote in result.data {
                    if let emoteData = await Request.perform(.GET, to: URL(string: emote.images.url_1x)!)  {
                        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.name + ".png"))
                        let filePath = folder.appendingPathComponent("\(emote.name).png")
                        try emoteData.write(to: filePath, options: .atomic)
                    }
                    
                }
            } catch {
                print("Twitch channel emote get failed", error.localizedDescription)
            }
        } else {
            print("Failed to get channel emote data")
        }
    }
    
    static func getGlobalEmotesBTTV() async {
        let endpoint = "https://api.betterttv.net/3/cached/emotes/global"
        let decoder = JSONDecoder()
        
        let folder = cachesDirectory.appendingPathComponent("BTTVGlobalEmotes")
        
        if fileManager.fileExists(atPath: folder.path) {
            print("Folder already exists")
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
                for emote in contents {
                    let emotePath = folder.appendingPathComponent(emote)
                    let emoteData = try Data(contentsOf: emotePath)
                    cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote))
                }
            } catch {
                print("Fail")
            }
        } else if let data = await Request.perform(.GET, to: URL(string: endpoint)!) {
            do {
                let result = try decoder.decode([EmoteBTTV].self, from: data)
                for emote in result {
                    let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                    if let emoteData = emoteData {
                        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.code + ".png"))
                        let filePath = folder.appendingPathComponent("\(emote.code).png")
                        try emoteData.write(to: filePath, options: .atomic)
                    } else {
                        print("BTTV GLOBAL FAILED")
                    }
                }
            } catch {
                print("Failed to decode global BTTV", error.localizedDescription)
            }
        } else {
            print("Failed to get global BTTV emotes")
        }
    }
    
    static func getChannelEmotesBTTV(id: String) async {
        let endpoint = "https://api.betterttv.net/3/cached/users/twitch/\(id)"
        let decoder = JSONDecoder()
        
        let folder = cachesDirectory.appendingPathComponent("BTTVChannelEmotes/\(id)")
        
        if fileManager.fileExists(atPath: folder.path) {
            print("Folder already exists")
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
                for emote in contents {
                    let emotePath = folder.appendingPathComponent(emote)
                    let emoteData = try Data(contentsOf: emotePath)
                    cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote))
                }
            } catch {
                print("Fail")
            }
        } else if let data = await Request.perform(.GET, to: URL(string: endpoint)!) {
            do {
                let result = try decoder.decode(ChannelEmotesBTTV.self, from: data)
                for emote in result.channelEmotes {
                    let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                    if let emoteData = emoteData {
                        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.code + ".png"))
                        let filePath = folder.appendingPathComponent("\(emote.code).png")
                        try emoteData.write(to: filePath, options: .atomic)
                    } else {
                        print("BTTV CHANNEL EMOTE FAILED")
                    }
                }
                for emote in result.sharedEmotes {
                    let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                    if let emoteData = emoteData {
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.code + ".png"))
                    } else {
                        print("BTTV SHARED EMOTE FAILED")
                    }
                }
            } catch {
                print("Failed to decode BTTV Channel", error.localizedDescription)
            }
        } else {
            print("Failed to get channel BTTV emotes")
        }
    }
    
    static func getChannelEmotesFFZ(id: String) async {
        let endpoint = "https://api.betterttv.net/3/cached/frankerfacez/users/twitch/\(id)"
        let decoder = JSONDecoder()
        
        let folder = cachesDirectory.appendingPathComponent("FFZChannelEmotes/\(id)")
        
        if fileManager.fileExists(atPath: folder.path) {
            print("Folder already exists")
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
                for emote in contents {
                    let emotePath = folder.appendingPathComponent(emote)
                    let emoteData = try Data(contentsOf: emotePath)
                    cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote))
                }
            } catch {
                print("Fail")
            }
        } else if let data = await Request.perform(.GET, to: URL(string: endpoint)!) {
            do {
                let result = try decoder.decode([ChannelEmotesFFZ].self, from: data)
                for emote in result {
                    let emoteData = await Request.perform(.GET, to: URL(string: emote.images.emote1x)!)
                    if let emoteData = emoteData {
                        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.code + ".png"))
                        let filePath = folder.appendingPathComponent("\(emote.code).png")
                        try emoteData.write(to: filePath, options: .atomic)
                    } else {
                        print("FFZ CHANNEL EMOTE FAILED")
                    }
                }
            } catch {
                print("Failed to decode Global FFZ", error.localizedDescription)
            }
        } else {
            print("Failed to get channel FFZ emotes")
        }
    }
    
    static func getGlobalEmotesFFZ() async {
        
    }
    
    // Badges
    func parseUserTags(_ mappings: [String:String]) -> String? {
        if mappings["@badge-info"] == nil {
//            let turbo = mappings["turbo"]
//            let badges = mappings["badges"]
            let color = mappings["color"]
//            let subscriber = mappings["subscriber"]
//            let mod = mappings["mod"]
            
            return color
        }
        return nil
    }
    
    enum Badge {
        case global
        case channel
    }
    
    static func getBadges(badgeType: Badge, token: String, id: String? = nil) async -> [Badges]? {
        var endpoint: String
        
        switch badgeType {
        case .global:
            endpoint = "https://api.twitch.tv/helix/chat/badges/global"
        case .channel:
            endpoint = "https://api.twitch.tv/helix/chat/badges?broadcaster_id=\(id!)"
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let headers = ["Authorization":"Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi" ]
        
        if let data = await Request.perform(.GET, to: URL(string: endpoint)!, headers: headers) {
            do {
                let result = try decoder.decode(BadgeData.self, from: data)
                return result.data
            } catch {
                print("Badge failed ", error.localizedDescription)
                return nil
            }
        } else {
            return nil
        }
    }

}
