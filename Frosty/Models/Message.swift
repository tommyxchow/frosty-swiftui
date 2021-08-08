//
//  Message.swift
//  Frosty
//
//  Created by Tommy Chow on 6/19/21.
//

import Foundation

struct Message: Hashable {
    let tags: Dictionary<String, String>
    let type: IRCCommand
    let message: String
}

enum IRCCommand {
    case CLEARCHAT
    case CLEARMSG
    case GLOBALUSERSTATE
    case PRIVMSG
    case ROOMSTATE
    case USERNOTICE
    case USERSTATE
}
