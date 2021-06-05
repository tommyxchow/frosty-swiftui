//
//  User.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

struct UserData: Decodable {
    let data: [User]
}

struct User: Decodable {
    let id : String
    let login: String
    let type: String
    let broadcasterType: String
    let description: String
    let profileImageUrl: String
    let offlineImageUrl: String
    let viewCount: Int
    let email: String
    let createdAt: String
}
