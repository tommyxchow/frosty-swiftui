//
//  Commands.swift
//  Commands
//
//  Created by Tommy Chow on 8/9/21.
//

import Foundation

enum IRCCommand {
    case CLEARCHAT
    case CLEARMSG
    case GLOBALUSERSTATE
    case PRIVMSG
    case ROOMSTATE
    case USERNOTICE
    case USERSTATE
}

struct ROOMSTATE {
    var emoteOnly: String?
    var followersOnly: String?
    var r9k: String?
    var slow: String?
    var subsOnly: String?
}
