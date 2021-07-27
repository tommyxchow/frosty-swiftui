//
//  Emotes.swift
//  Frosty
//
//  Created by Tommy Chow on 6/15/21.
//

import Foundation

// Twitch Emotes
struct EmoteDataTwitch: Decodable {
    let data: [EmoteTwitch]
}

struct EmoteTwitch: Decodable {
    struct Images: Decodable {
        let url_1x: String
        let url_2x: String
        let url_4x: String
    }
    
    let id: String
    let name: String
    let images: Images
    let tier: String?
    let emoteType: String?
    let emoteSetId: String?
}


// BTTV Emotes
struct EmoteBTTVGlobal: Decodable {
    let id: String
    let code: String
    let imageType: String
    let userId: String
}

struct EmoteBTTVChannel: Decodable {
    struct UserBTTV: Decodable {
        let id: String
        let name: String
        let displayName: String
        let providerId: String
    }
    
    struct SharedEmoteBTTV: Decodable {
        let id: String
        let code: String
        let imageType: String
        let user: UserBTTV
    }
    
    let id: String
    let bots: [String]
    let channelEmotes: [EmoteBTTVGlobal]
    let sharedEmotes: [SharedEmoteBTTV]
}


// FFZ Emotes
struct EmotesFFZ: Decodable {
    struct UserFFZ: Decodable {
        let id: Int
        let name: String
        let displayName: String
    }
    
    struct ImagesFFZ: Decodable {
        let emote1x: String
        let emote2x: String?
        let emote4x: String?
        
        enum CodingKeys: String, CodingKey {
            case emote1x = "1x"
            case emote2x = "2x"
            case emote4x = "4x"
        }
    }
    
    let id: Int
    let user: UserFFZ
    let code: String
    let images: ImagesFFZ
    let imageType: String
}
