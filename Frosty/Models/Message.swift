//
//  Message.swift
//  Frosty
//
//  Created by Tommy Chow on 6/19/21.
//

import Foundation

struct Message: Hashable {
    let tags: [String: String]
    let type: IRCCommand
    var message: String
}
