//
//  ChatManager.swift
//  Frosty
//
//  Created by Tommy Chow on 6/16/21.
//

import Foundation
import SDWebImage
import SDWebImageSwiftUI
import SwiftUI
import NukeUI

// TODO: Account for interruptions on connection (user leaves while emotes are being fetched)

// TODO: Get global sub emotes through the twitch tags

// TODO: Instead of fetching from cache, storing emote data in a dictionary might be more efficient

// TODO: Instead of storing folder per user, store single folders with BTTV/FFZ/Twitch emotes each. This will reduce redundant operations (fetching and decoding emotes that already exists). Would likely reduce loading time due to less decoding. Also, use userdefaults to store a registry per channel

// FIXME: When exiting the channel and rejoining, certain emotes won't return (i.e. PogU or BTTV/FFZ?). Look into caching bugs
// fixed: Wasn't writing BTTV shared emotes to the cache directory

// FIXME: Twitch global emotes aren't being rendered in chat (i.e. LUL, Kappa, 4Head). Might be something to do with emotify
// fixed: Forgot to add the await for global emotes in viewmodel

struct ChatManager {
    static var emoteToImage: [String:WebImage] = [:]
    static var dictionary: [String:Text] = [:]
    
    
    static func getGlobalAssets(token: String) async -> [String:URL] {
        var finalRegisty: [String:URL] = [:]

        do {
            async let twitchGlobalEmotes = Request.assetToUrl(requestedDataType: .emoteTwitchGlobal, token: token)
            async let bttvGlobalEmotes = Request.assetToUrl(requestedDataType: .emoteBTTVGlobal)
            async let ffzGlobalEmotes = Request.assetToUrl(requestedDataType: .emoteFFZGlobal)
            async let twitchGlobalBadges = Request.assetToUrl(requestedDataType: .badgeTwitchGlobal, token: token)
            
            let registries = try await [twitchGlobalEmotes, bttvGlobalEmotes, ffzGlobalEmotes, twitchGlobalBadges]
            for registry in registries {
                finalRegisty.merge(registry) {(_,new) in new}
            }
        } catch {
            print("Failed to get global assets: ", error.localizedDescription)
        }
        return finalRegisty
    }
    
    static func getChannelAssets(token: String, id: String) async -> [String:URL] {
        var finalRegisty: [String:URL] = [:]
        do {
            async let twitchChannelEmotes = Request.assetToUrl(requestedDataType: .emoteTwitchChannel(id: id), token: token)
            async let bttvChannelEmotes = Request.assetToUrl(requestedDataType: .emoteBTTVChannel(id: id))
            async let ffzChannelEmotes = Request.assetToUrl(requestedDataType: .emoteFFZChannel(id: id))
            async let twitchChannelBadges = Request.assetToUrl(requestedDataType: .badgeTwitchChannel(id: id), token: token)
            
            let registries = try await [twitchChannelEmotes, bttvChannelEmotes, ffzChannelEmotes, twitchChannelBadges]
            for registry in registries {
                finalRegisty.merge(registry) {(_,new) in new}
            }
        } catch {
            print("Failed to get channel assets: ", error.localizedDescription)
        }
        return finalRegisty
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
