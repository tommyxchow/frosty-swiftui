//
//  Streamer.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import Foundation

struct StreamerData: Decodable {
    let data: [StreamerInfo]
}

struct StreamerInfo: Decodable {
    var id: String
    var userId: String
    var userLogin: String
    var userName: String
    var gameId: String
    var gameName: String
    var type: String
    var title: String
    var viewerCount: Int
    var startedAt: String
    var language: String
    var thumbnailUrl: String
    var tagIds: [String]
    var isMature: Bool
    
    var thumbnail: Data?
}

extension StreamerInfo {
    static var data: [StreamerInfo] {
        [
            StreamerInfo(id: "", userId: "", userLogin: "xqcow", userName: "xQcOW", gameId: "", gameName: "VALORANT", type: "live", title: "GOD GAMER VALORANT PLACEMENTS (GONE WRONG) (SAME RESULT)", viewerCount: 96422, startedAt: "", language: "en", thumbnailUrl: "thumbnail-xqcow", tagIds: [], isMature: false),
            StreamerInfo(id: "", userId: "", userLogin: "lirik", userName: "Lirik", gameId: "", gameName: "Just Chatting", type: "live", title: "LOL", viewerCount: 11933, startedAt: "", language: "en", thumbnailUrl: "thumbnail-lirik", tagIds: [], isMature: false),
            StreamerInfo(id: "", userId: "", userLogin: "mizkif", userName: "Mizkif", gameId: "", gameName: "Just Chatting", type: "live", title: "DRAMA DRAMA DRAMA", viewerCount: 4547, startedAt: "", language: "en", thumbnailUrl: "404_preview", tagIds: [], isMature: false)
        ]
    }
}
