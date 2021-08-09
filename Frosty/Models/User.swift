//
//  User.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

struct Users: Decodable {
    let data: [User]
}

struct User: Decodable, Equatable {
    let id: String
    let login: String
    let displayName: String
    let type: String
    let broadcasterType: String
    let description: String
    let profileImageUrl: String
    let offlineImageUrl: String
    let viewCount: Int
    let createdAt: String
}

extension User {
    static let sampleUser = User(id: "888", login: "Clamfucius", displayName: "Clamfucius", type: "", broadcasterType: "", description: "", profileImageUrl: "https://static-cdn.jtvnw.net/user-default-pictures-uv/ead5c8b2-a4c9-4724-b1dd-9f00b46cbd3d-profile_image-300x300.png", offlineImageUrl: "", viewCount: 888, createdAt: "")
}
