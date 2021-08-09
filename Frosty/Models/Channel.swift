//
//  Channel.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import Foundation

struct Channels: Decodable {
    struct Pagination: Decodable {
        let cursor: String?
    }

    let data: [Channel]
    let pagination: Pagination
}

struct Channel: Decodable, Hashable {
    let id: String
    let userId: String
    let userLogin: String
    let userName: String
    let gameId: String
    let gameName: String
    let type: String
    let title: String
    let viewerCount: Int
    let startedAt: String
    let language: String
    var thumbnailUrl: String
    let tagIds: [String]
    let isMature: Bool
}

extension Channel {
    static var sampleChannels: [Channel] {
        [
            Channel(id: "", userId: "", userLogin: "xqcow", userName: "xQcOW", gameId: "", gameName: "VALORANT", type: "live", title: "GOD GAMER VALORANT PLACEMENTS (GONE WRONG) (SAME RESULT)", viewerCount: 96422, startedAt: "", language: "en", thumbnailUrl: "https://static-cdn.jtvnw.net/previews-ttv/live_user_xqcow-{width}x{height}.jpg", tagIds: [], isMature: false),
            Channel(id: "", userId: "", userLogin: "lirik", userName: "Lirik", gameId: "", gameName: "Just Chatting", type: "live", title: "LOL", viewerCount: 11933, startedAt: "", language: "en", thumbnailUrl: "https://static-cdn.jtvnw.net/previews-ttv/live_user_lirik-{width}x{height}.jpg", tagIds: [], isMature: false),
            Channel(id: "", userId: "", userLogin: "mizkif", userName: "Mizkif", gameId: "", gameName: "Just Chatting", type: "live", title: "DRAMA DRAMA DRAMA", viewerCount: 4547, startedAt: "https://static-cdn.jtvnw.net/previews-ttv/live_user_mizkif-{width}x{height}.jpg", language: "en", thumbnailUrl: "404_preview", tagIds: [], isMature: false)
        ]
    }
}
