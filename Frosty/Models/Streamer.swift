//
//  Streamer.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import Foundation

struct StreamerData: Decodable {
    let data: [StreamerInfo]
    let pagination: Pagination
}

struct Pagination: Decodable {
    let cursor: String?
}

struct StreamerInfo: Decodable {
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

extension StreamerInfo {
    static var data: [StreamerInfo] {
        [
            StreamerInfo(id: "", userId: "", userLogin: "xqcow", userName: "xQcOW", gameId: "", gameName: "VALORANT", type: "live", title: "GOD GAMER VALORANT PLACEMENTS (GONE WRONG) (SAME RESULT)", viewerCount: 96422, startedAt: "", language: "en", thumbnailUrl: "thumbnail-xqcow", tagIds: [], isMature: false),
            StreamerInfo(id: "", userId: "", userLogin: "lirik", userName: "Lirik", gameId: "", gameName: "Just Chatting", type: "live", title: "LOL", viewerCount: 11933, startedAt: "", language: "en", thumbnailUrl: "thumbnail-lirik", tagIds: [], isMature: false),
            StreamerInfo(id: "", userId: "", userLogin: "mizkif", userName: "Mizkif", gameId: "", gameName: "Just Chatting", type: "live", title: "DRAMA DRAMA DRAMA", viewerCount: 4547, startedAt: "", language: "en", thumbnailUrl: "404_preview", tagIds: [], isMature: false)
        ]
    }
}
