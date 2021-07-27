//
//  Message.swift
//  Frosty
//
//  Created by Tommy Chow on 6/19/21.
//

import Foundation

struct Message: Hashable {
    let name: String
    let message: String
    let tags: Dictionary<String, String>
}
