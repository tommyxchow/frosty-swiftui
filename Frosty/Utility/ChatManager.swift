//
//  ChatManager.swift
//  Frosty
//
//  Created by Tommy Chow on 6/16/21.
//

import Foundation

// TODO: Account for interruptions on connection (user leaves while emotes are being fetched)

// TODO: Get global sub emotes through the twitch tags

// TODO: Instead of fetching from cache, storing emote data in a dictionary might be more efficient

// TODO: Instead of storing folder per user, store single folders with BTTV/FFZ/Twitch emotes each. This will reduce redundant operations (fetching and decoding emotes that already exists). Would likely reduce loading time due to less decoding. Also, use userdefaults to store a registry per channel

// FIXME: When exiting the channel and rejoining, certain emotes won't return (i.e. PogU or BTTV/FFZ?). Look into caching bugs
// fixed: Wasn't writing BTTV shared emotes to the cache directory

// FIXME: Twitch global emotes aren't being rendered in chat (i.e. LUL, Kappa, 4Head). Might be something to do with emotify
// fixed: Forgot to add the await for global emotes in viewmodel

struct ChatManager {
    
    static func getGlobalEmotes(token: String) async {
        do {
            async let twitchGlobalEmotes: () = Cache.cacheContents(requestedDataType: .emoteTwitchGlobal, token: token, registryId: "twitchGlobalEmotes")
            async let bttvGlobalEmotes: () = Cache.cacheContents(requestedDataType: .emoteBTTVGlobal, registryId: "bttvGlobalEmotes")
            async let ffzGlobalEmotes: () = Cache.cacheContents(requestedDataType: .emoteFFZGlobal, registryId: "ffzGlobalEmotes")
            async let twitchGlobalBadges: () = Cache.cacheContents(requestedDataType: .badgeTwitchGlobal, token: token, registryId: "twitchGlobalBadges")
            
            _ = try await [twitchGlobalEmotes, bttvGlobalEmotes, ffzGlobalEmotes, twitchGlobalBadges]
        } catch {
            print("Failed to get global emotes, ", error.localizedDescription)
        }
    }
    
    static func getChannelEmotes(token: String, id: String) async {
        do {
            async let twitchChannelEmotes: () = Cache.cacheContents(requestedDataType: .emoteTwitchChannel(id: id), token: token, registryId: "twitchChannelEmotes_\(id)")
            async let bttvChannelEmotes: () = Cache.cacheContents(requestedDataType: .emoteBTTVChannel(id: id), registryId: "bttvChannelEmotes_\(id)")
            async let ffzChannelEmotes: () = Cache.cacheContents(requestedDataType: .emoteFFZChannel(id: id), registryId: "ffzChannelEmotes_\(id)")
            async let twitchChannelBadges: () = Cache.cacheContents(requestedDataType: .badgeTwitchChannel(id: id), token: token, registryId: "twitchChannelBadges_\(id)")
            
            _ = try await [twitchChannelEmotes, bttvChannelEmotes, ffzChannelEmotes, twitchChannelBadges]
        } catch {
            print("Failed to get channel emotes, ", error.localizedDescription)
        }
    }
    
    // Badges
    func parseUserTags(_ mappings: [String:String]) -> String? {
        print(mappings)
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
