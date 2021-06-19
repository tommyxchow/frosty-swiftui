//
//  Message.swift
//  Frosty
//
//  Created by Tommy Chow on 6/19/21.
//

import Foundation

struct Message: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let message: String
    let tags: Dictionary<String, String>
}
