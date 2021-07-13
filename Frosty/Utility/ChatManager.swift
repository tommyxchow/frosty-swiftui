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
    
    static func getGlobalAssets(token: String) async {
        do {
            async let twitchGlobalEmotes: () = CacheManager.cacheContents(requestedDataType: .emoteTwitchGlobal, token: token, registryId: "twitchGlobalEmotes")
            async let bttvGlobalEmotes: () = CacheManager.cacheContents(requestedDataType: .emoteBTTVGlobal, registryId: "bttvGlobalEmotes")
            async let ffzGlobalEmotes: () = CacheManager.cacheContents(requestedDataType: .emoteFFZGlobal, registryId: "ffzGlobalEmotes")
            async let twitchGlobalBadges: () = CacheManager.cacheContents(requestedDataType: .badgeTwitchGlobal, token: token, registryId: "twitchGlobalBadges")
            
            _ = try await [twitchGlobalEmotes, bttvGlobalEmotes, ffzGlobalEmotes, twitchGlobalBadges]
        } catch {
            print("Failed to get global assets: ", error.localizedDescription)
        }
    }
    
    static func getChannelAssets(token: String, id: String) async {
        do {
            async let twitchChannelEmotes: () = CacheManager.cacheContents(requestedDataType: .emoteTwitchChannel(id: id), token: token, registryId: "twitchChannelEmotes_\(id)")
            async let bttvChannelEmotes: () = CacheManager.cacheContents(requestedDataType: .emoteBTTVChannel(id: id), registryId: "bttvChannelEmotes_\(id)")
            async let ffzChannelEmotes: () = CacheManager.cacheContents(requestedDataType: .emoteFFZChannel(id: id), registryId: "ffzChannelEmotes_\(id)")
            async let twitchChannelBadges: () = CacheManager.cacheContents(requestedDataType: .badgeTwitchChannel(id: id), token: token, registryId: "twitchChannelBadges_\(id)")
            
            _ = try await [twitchChannelEmotes, bttvChannelEmotes, ffzChannelEmotes, twitchChannelBadges]
        } catch {
            print("Failed to get channel assets: ", error.localizedDescription)
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

}
