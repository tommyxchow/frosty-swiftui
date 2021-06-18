//
//  EmoteManager.swift
//  Frosty
//
//  Created by Tommy Chow on 6/16/21.
//

import Foundation

struct EmoteManager {
    static let fileManager = FileManager.default
    static private let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    static let cache = NSCache<NSString, NSData>()
    static private let decoder = JSONDecoder()
    
    static func getGlobalEmotesTwitch(token: String) async {
        let endpoint = URL(string: "https://api.twitch.tv/helix/chat/emotes/global")!
        let headers = ["Authorization":"Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi" ]
        let folder = cachesDirectory.appendingPathComponent("GlobalEmotesTwitch")
        print(folder)
        
        if fileManager.fileExists(atPath: folder.path) {
            print("Folder already exists")
            if let files = fileManager.enumerator(atPath: folder.path) {
                while let emote = files.nextObject() as? String {
                    print("EMOTE EXISTS", emote)
                }
            }
        } else if let data = await Request.perform(.GET, to: endpoint, headers: headers) {
            do {
                try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                
                let result = try decoder.decode(EmoteDataTwitch.self, from: data)
                for emote in result.data {
                    let emoteData = await Request.perform(.GET, to: URL(string: emote.images.url_1x)!)
                    if let emoteData = emoteData {
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.name))
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
        //decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if let data = await Request.perform(.GET, to: endpoint, headers: headers) {
            do {
                let result = try decoder.decode(EmoteDataTwitch.self, from: data)
                for emote in result.data {
                    if let emoteData = await Request.perform(.GET, to: URL(string: emote.images.url_1x)!)  {
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.name))
                    }
                    
                }
            } catch {
                print("Failed to decode", error.localizedDescription)
            }
        } else {
            print("Failed to get channel emote data")
        }
    }
    
    static func getGlobalEmotesBTTV() async {
        let endpoint = "https://api.betterttv.net/3/cached/emotes/global"
        let decoder = JSONDecoder()
        
        if let data = await Request.perform(.GET, to: URL(string: endpoint)!) {
            do {
                let result = try decoder.decode([EmoteBTTV].self, from: data)
                for emote in result {
                    let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                    if let emoteData = emoteData {
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.code))
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
        
        if let data = await Request.perform(.GET, to: URL(string: endpoint)!) {
            do {
                let result = try decoder.decode(ChannelEmotesBTTV.self, from: data)
                for emote in result.channelEmotes {
                    let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                    if let emoteData = emoteData {
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.code))
                    } else {
                        print("BTTV CHANNEL EMOTE FAILED")
                    }
                }
                for emote in result.sharedEmotes {
                    let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                    if let emoteData = emoteData {
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.code))
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
        
        if let data = await Request.perform(.GET, to: URL(string: endpoint)!) {
            do {
                let result = try decoder.decode([ChannelEmotesFFZ].self, from: data)
                for emote in result {
                    let emoteData = await Request.perform(.GET, to: URL(string: emote.images.emote1x)!)
                    if let emoteData = emoteData {
                        cache.setObject(NSData(data: emoteData), forKey: NSString(string: emote.code))
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
}
