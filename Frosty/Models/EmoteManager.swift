//
//  EmoteManager.swift
//  Frosty
//
//  Created by Tommy Chow on 6/16/21.
//

import Foundation

struct EmoteManager {
    static let fileManager = FileManager.default
    static let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    
    static func getGlobalEmotesTwitch(token: String) async {
        let endpoint = URL(string: "https://api.twitch.tv/helix/chat/emotes/global")!
        let headers = ["Authorization":"Bearer \(token)", "Client-Id": "k6tnwmfv24ct9pzanhnp2x1yht30oi" ]
         
        if let data = await Request.perform(.GET, to: endpoint, headers: headers) {
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(EmoteDataTwitch.self, from: data)
                for emote in result.data {
                    let finalURL = cachesDirectory.appendingPathComponent("\(emote.name).png")
                    if !fileManager.fileExists(atPath: finalURL.path) {
                        print(emote)
                        let emoteData = await Request.perform(.GET, to: URL(string: emote.images.url_1x)!)
                        if let emoteData = emoteData {
                            try emoteData.write(to: finalURL, options: .atomic)
                        } else {
                            print("Twitch emote request failed")
                        }
                    } else {
                        print("FILE ALREADY EXISTS")
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
            print(id)
            print(String(data: data, encoding: .utf8)!)
            do {
                let result = try decoder.decode(EmoteDataTwitch.self, from: data)
                print(result)
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
                    let path = cachesDirectory.appendingPathComponent("\(emote.code).png")
                    if !fileManager.fileExists(atPath: path.path) {
                        let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                        if let emoteData = emoteData {
                            try emoteData.write(to: path, options: .atomic)
                        } else {
                            print("BTTV GLOBAL FAILED")
                        }
                    } else {
                        print("BTTV Global Emote already saved")
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
        print(id)
        let endpoint = "https://api.betterttv.net/3/cached/users/twitch/\(id)"
        let decoder = JSONDecoder()
        
        if let data = await Request.perform(.GET, to: URL(string: endpoint)!) {
            do {
                let result = try decoder.decode(ChannelEmotesBTTV.self, from: data)
                for emote in result.channelEmotes {
                    let path = cachesDirectory.appendingPathComponent("\(emote.code).png")
                    if !fileManager.fileExists(atPath: path.path) {
                        let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                        if let emoteData = emoteData {
                            try emoteData.write(to: path, options: .atomic)
                        } else {
                            print("BTTV CHANNEL EMOTE FAILED")
                        }
                    } else {
                        print("BTTV Channel Emote already saved")
                    }
                }
                for emote in result.sharedEmotes {
                    let path = cachesDirectory.appendingPathComponent("\(emote.code).png")
                    if !fileManager.fileExists(atPath: path.path) {
                        let emoteData = await Request.perform(.GET, to: URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x")!)
                        if let emoteData = emoteData {
                            try emoteData.write(to: path, options: .atomic)
                        } else {
                            print("BTTV SHARED EMOTE FAILED")
                        }
                    } else {
                        print("BTTV Shared Emote already saved")
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
        print(id)
        let endpoint = "https://api.betterttv.net/3/cached/frankerfacez/users/twitch/\(id)"
        let decoder = JSONDecoder()
        
        if let data = await Request.perform(.GET, to: URL(string: endpoint)!) {
            do {
                let result = try decoder.decode([ChannelEmotesFFZ].self, from: data)
                for emote in result {
                    let path = cachesDirectory.appendingPathComponent("\(emote.code).png")
                    if !fileManager.fileExists(atPath: path.path) {
                        let emoteData = await Request.perform(.GET, to: URL(string: emote.images.emote1x)!)
                        if let emoteData = emoteData {
                            try emoteData.write(to: path, options: .atomic)
                        } else {
                            print("FFZ CHANNEL EMOTE FAILED")
                        }
                    } else {
                        print("FFZ Channel Emote already saved")
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
