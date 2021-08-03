//
//  ChatManager.swift
//  Frosty
//
//  Created by Tommy Chow on 6/16/21.
//

import Foundation
import SwiftUI

// TODO: Get global sub emotes through the twitch tags

struct ChatManager {
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
