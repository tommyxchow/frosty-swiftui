//
//  Emote.swift
//  Frosty
//
//  Created by Tommy Chow on 6/15/21.
//

import Foundation

struct GlobalEmotesData: Decodable {
    let data: [GlobalEmote]
}

struct GlobalEmote: Decodable {
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
