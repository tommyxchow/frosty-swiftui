//
//  Badge.swift
//  Frosty
//
//  Created by Tommy Chow on 6/18/21.
//

import Foundation

struct Badges: Decodable {
    let data: [Badge]
}

struct BadgeImages: Decodable {
    let id: String
    let imageUrl1X: String
    let imageUrl2X: String
    let imageUrl4X: String
}

struct Badge: Decodable {
    let setId: String
    let versions: [BadgeImages]

}
