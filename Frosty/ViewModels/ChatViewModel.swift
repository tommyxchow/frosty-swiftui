//
//  ChatViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/5/21.
//

import Foundation
import SwiftUI
import FlexLayout
import Nuke
import Gifu

// TODO: Maybe instead of closing ws connection when leaving room, use PART and JOIN for faster connection. Only dc the ws connection when user exits the app
// TODO: Fix this monstrosity of a file

class ChatViewModel: ObservableObject {
    @Published var messages = [Message]()
    @Published var chatBoxMessage = ""
    @Published var autoScrollEnabled = true
    @Published var roomState: ROOMSTATE = ROOMSTATE()

    private let websocket = URLSession.shared.webSocketTask(with: URL(string: "wss://irc-ws.chat.twitch.tv:443")!)

    var assetToUrl = [String: URL]()
    var emoteIdToWord = [String: String]()
    var emoteStats = [String: Int]()

    func start(token: String, user: String, channelName: String) async {
        let channel: [User] = await Request.getUser(login: channelName, token: token)

        if channel.isEmpty {
            return
        }

        async let globalAssets: [String: URL] = Request.getGlobalAssets(token: token)
        async let channelAssets: [String: URL] = Request.getChannelAssets(token: token, id: channel.first!.id)

        let assetsToUrl = await [globalAssets, channelAssets]

        for registry in assetsToUrl {
            assetToUrl.merge(registry) {(_, new) in new}
        }

        print("Starting chat!")

        let PASS = URLSessionWebSocketTask.Message.string("PASS oauth:\(token)")
        let NICKNAME = URLSessionWebSocketTask.Message.string("NICK \(user)")
        let JOIN = URLSessionWebSocketTask.Message.string("JOIN #\(channelName)")
        let TAG = URLSessionWebSocketTask.Message.string("CAP REQ :twitch.tv/tags")
        let COMMAND = URLSessionWebSocketTask.Message.string("CAP REQ :twitch.tv/commands")
        let END = URLSessionWebSocketTask.Message.string("CAP END")
        let CAP = URLSessionWebSocketTask.Message.string("CAP LS 302")
        // let PART = URLSessionWebSocketTask.Message.string("PART #\(chanelName)")

        let commands = [CAP, PASS, NICKNAME, COMMAND, TAG, END, JOIN]

        websocket.resume()

        for command in commands {
            websocket.send(command) { error in
                if let error = error {
                    print("WS CONNECTION FAILED", error.localizedDescription)
                    return
                }
            }
        }

        receive()
    }

    func end() {
        print("Ending chat")
        websocket.cancel(with: .goingAway, reason: nil)
        messages.removeAll()
    }

    func receive() {
        websocket.receive { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let response):
                switch response {
                case .data(let data):
                    print("WS DATA ", data)
                case .string(let stringResponse):
                    self.handleWebsocketResponse(response: stringResponse)
                @unknown default:
                    print("ERROR")
                }
                self.receive()
            }
        }
    }

    func handleWebsocketResponse(response: String) {
        // Upon receiving a ping, send back a pong to maintain the connection.
        if response.first == "P" {
            let message = URLSessionWebSocketTask.Message.string("PONG :tmi.twitch.tv")
            self.websocket.send(message) { error in
                if let error = error {
                    print("Failed to send PONG: \(error)")
                }
            }
        // Receiving a twitch IRC message
        } else if response.first == "@" {
            DispatchQueue.main.async {
                if let message = self.parseMessage(response) {
                    var newList = self.messages
                    newList.append(message)
                    // TODO: Investigate array slicing to potentially improve performance
                    if newList.count > 100, self.autoScrollEnabled {
                        newList.removeFirst(20)
                    }
                    self.messages = newList
                }
            }
        } else {
            print("Unknown websocket response")
        }
    }

    // FIXME: Messages will occasionally show tags/not parse correctly, maybe whitespace?
    func parseMessage(_ whole: String) -> Message? {
        // We have three parts:
        // 1. The tags of the IRC message
        // 2. The metadata (tag category, channel)
        // 3. The message itself
        // First, slice the message tags (1) and set aside the rest for later
        let tagAndMessageDivider = whole.firstIndex(of: " ")!
        let tags = String(whole[...whole.index(before: tagAndMessageDivider)].dropFirst()).unescapeIRCTags()
        let message = whole[whole.index(after: tagAndMessageDivider)...]

        // Next, parse and map the tags to a dictionary.
        var mappedTags = [String: String]()

        tags.split(separator: ";")
            .forEach { tag in
                if tag.last != "=" {
                    let tagSplit = tag.components(separatedBy: "=")
                    mappedTags[tagSplit[0]] = tagSplit[1]
                }
            }

        // Now, split the metadat and message up
        // Index 0 is username of sender (user)
        // Index 1 is message/command type
        // Index 2 is #channel name that we are currently chatting in
        // Index 3 is the :message that is sent by the user
        let splitMessage = message.split(separator: " ", maxSplits: 3)
        let username = splitMessage[0]
        let command = splitMessage[1]

        switch command {
        case "CLEARCHAT":
            print("Someone was banned...")
            clearChat(tags: mappedTags, user: String(username))
        case "CLEARMSG":
            print("A message was deleted...")
            clearMessage(tags: mappedTags)
        case "GLOBALUSERSTATE":
            break
        case "PRIVMSG":
            print(whole)
            print(chatBoxMessage)
            print(mappedTags)
            return privateMessage(tags: mappedTags, chatMessage: String(splitMessage[3]))
        case "ROOMSTATE":
            roomState(tags: mappedTags)
        case "USERNOTICE":
            break
        case "USERSTATE":
            break
        default:
            break
        }

        return nil
    }

    // TODO: Append a \(user) was banned announcement extra shame (as an option)
    /// Purges all chat messages in a channel, or purges chat messages from a specific user, typically after a timeout or ban.
    func clearChat(tags: [String: String], user: String) {
        let newMessage: String
        // If the ban duration is omitted, the user is permanently banned.
        // This is the only provided tag, so no tags = perma'd.
        print(tags)
        if tags.isEmpty {
            newMessage = "This user has been permanently banned."
        } else {
            newMessage = "Banned for \(tags["ban-duration"]!) seconds."
        }
        // Native implementation: Loop through the array, find and replace
        // Future optimization: Maintain dictioanry of user to index
        for (index, message) in messages.enumerated() {
            if message.tags["display-name"] == user {
                var bannedMessage = message
                bannedMessage.message = newMessage
                messages[index] = bannedMessage
            }
        }
    }

    /// Removes a single message from a channel. This is triggered by the/delete <target-msg-id> command on IRC.
    func clearMessage(tags: [String: String]) {
        print(tags)
        for (index, message) in messages.enumerated() {
            if message.tags["id"] == tags["target-msg-id"]! {
                var removedMessage = message
                removedMessage.message = "This message has been removed."
                messages[index] = removedMessage
                break
            }
        }
    }

    func privateMessage(tags: [String: String], chatMessage: String) -> Message {
        let chatMessage = chatMessage.dropFirst().dropLast().utf16
        if let emoteTags = tags["emotes"] {
            let emotes = emoteTags.split(separator: "/")

            for emoteIdAndPosition in emotes {
                // Get the split
                let indexBetweenIdAndPositions = emoteIdAndPosition.firstIndex(of: ":")!

                // Get the ID
                let emoteId = String(emoteIdAndPosition[..<indexBetweenIdAndPositions])

                if emoteIdToWord[emoteId] != nil {
                    continue
                }

                // Get the provided range of the emote in the message
                // If there are multiple, get the first one
                let range: Substring
                if let endOfFirstEmotePosition = emoteIdAndPosition.firstIndex(of: ",") {
                    // Get the index position of the emote and convert it to int
                    range = emoteIdAndPosition[emoteIdAndPosition.index(after: indexBetweenIdAndPositions)..<endOfFirstEmotePosition]
                } else {
                    range = emoteIdAndPosition[emoteIdAndPosition.index(after: indexBetweenIdAndPositions)..<emoteIdAndPosition.endIndex]
                }

                let indexSplit = range.split(separator: "-")
                let startIndex = Int(indexSplit[0])!
                let endIndex = Int(indexSplit[1])!

                // Slice the word
                let emoteWord = String(chatMessage.prefix(endIndex+1).dropFirst(startIndex))!

                emoteIdToWord[emoteId] = emoteWord
                assetToUrl[emoteWord] = URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(emoteId)/default/dark/3.0")!
            }
        }
        return Message(tags: tags, type: .PRIVMSG, message: String(chatMessage)!)
    }

    // Update the room state
    func roomState(tags: [String: String]) {
        print(tags)
        roomState.emoteOnly = tags["emote-only"]
        roomState.followersOnly = tags["followers-only"]
        roomState.r9k = tags["r9k"]
        roomState.slow = tags["slow"]
        roomState.subsOnly = tags["subs-only"]
    }

    func sendMessage(message: String, userName: String, channelName: String) {
        chatBoxMessage.removeAll()
        let webSocketMessage = URLSessionWebSocketTask.Message.string("PRIVMSG #\(channelName) :\(message)")

        websocket.send(webSocketMessage) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }

        messages.append(Message(tags: [:], type: .PRIVMSG, message: message))
    }
}

extension String {
    func unescapeIRCTags() -> String {
        return self.replacingOccurrences(of: "\\s", with: " ")
    }
}
