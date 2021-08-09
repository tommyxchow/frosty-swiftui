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
    @Published var chatBoxMessage: String = ""

    private let websocket = URLSession.shared.webSocketTask(with: URL(string: "wss://irc-ws.chat.twitch.tv:443")!)

    var chatting: Bool = false
    var assetToUrl = [String: URL]()
    var emoteIdToWord = [String: String]()

    func start(token: String, user: String, channelName: String) async {
        let channel: [User] = await Request.getUser(login: channelName, token: token)

        if channel.isEmpty {
            return
        }

        async let globalAssets: [String: URL] = getGlobalAssets(token: token)
        async let channelAssets: [String: URL] = getChannelAssets(token: token, id: channel.first!.id)

        let assetsToUrl = await [globalAssets, channelAssets]

        for registry in assetsToUrl {
            assetToUrl.merge(registry) {(_, new) in new}
        }

        print("Starting chat!")

        let PASS = URLSessionWebSocketTask.Message.string("PASS oauth:\(token)")
        let NICKNAME = URLSessionWebSocketTask.Message.string("NICK \(user)")
        let JOIN = URLSessionWebSocketTask.Message.string("JOIN #\(channelName.lowercased())")
        let TAG = URLSessionWebSocketTask.Message.string("CAP REQ :twitch.tv/tags")
        let COMMAND = URLSessionWebSocketTask.Message.string("CAP REQ :twitch.tv/commands")
        let END = URLSessionWebSocketTask.Message.string("CAP END")
        let CAP = URLSessionWebSocketTask.Message.string("CAP LS 302")
        // let PART = URLSessionWebSocketTask.Message.string("PART #\(chanelName.lowercased())")

        let commands = [CAP, PASS, NICKNAME, COMMAND, TAG, END, JOIN]

        websocket.resume()

        chatting = true

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
                    // print(string)
                    self.handleWebsocketResponse(response: stringResponse)
                @unknown default:
                    print("ERROR")
                }
                if self.chatting {
                    self.receive()
                }
            }
        }
    }

    func handleWebsocketResponse(response: String) {
        if response[response.startIndex] == "P" {
            let message = URLSessionWebSocketTask.Message.string("PONG :tmi.twitch.tv")
            self.websocket.send(message) { error in
                if let error = error {
                    print("Failed to send PONG: \(error)")
                }
            }
        }
        if response[response.startIndex] == "@" {
            DispatchQueue.main.async {
                if let parsed = self.buildMessage(response) {
                    var newList = self.messages
                    newList.append(parsed)
                    if newList.count > 80 {
                        newList.removeFirst(10)
                    }
                    self.messages = newList
                }
            }
        }
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

    func end() {
        print("Ending chat")
        websocket.cancel(with: .goingAway, reason: nil)
        messages.removeAll()
    }

    // FIXME: Messages will occasionally show tags/not parse correctly, maybe whitespace?
    func buildMessage(_ whole: String) -> Message? {
        let tagAndMessageDivider = whole.firstIndex(of: " ")!
        let tags = String(whole[...whole.index(before: tagAndMessageDivider)]).unescapeIRCTags()
        let message = whole[whole.index(after: tagAndMessageDivider)...]

        var mappedTags = [String: String]()

        tags.split(separator: ";")
            .forEach { tag in
                if tag.last != "=" {
                    let tagSplit = tag.components(separatedBy: "=")
                    mappedTags[tagSplit[0]] = tagSplit[1]
                }
            }

        // Split the message up
        // Index 0 is username of sender
        // Index 1 is message/command type
        // Index 2 is #channel name
        // Index 3 is the :message
        let splitMessage = message.split(separator: " ", maxSplits: 3)
        let username = splitMessage[0]
        let command = splitMessage[1]
        // let channel = splitMessage[2].removeFirst()

        if command == "PRIVMSG", username != ":jtv!jtv@jtv.tmi.twitch.tv" {
            let chatMessage = splitMessage[3].dropFirst().dropLast().utf16
//            print(mappedTags)
//            print(chatMesssage)
            if let emoteTags = mappedTags["emotes"] {
                let emotes = emoteTags.split(separator: "/")
                print(emotes)

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
                    print(emoteWord)

                    emoteIdToWord[emoteId] = emoteWord
                    assetToUrl[emoteWord] = URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(emoteId)/default/dark/3.0")!
                }
                // print(chatMessage, emotes)
            }
            return Message(tags: mappedTags, type: .PRIVMSG, message: String(chatMessage)!)
        }
        return nil
    }

    func getGlobalAssets(token: String) async -> [String: URL] {
        var finalRegisty = [String: URL]()

        do {
            async let twitchGlobalEmotes = Request.assetToUrl(requestedDataType: .emoteTwitchGlobal, token: token)
            async let bttvGlobalEmotes = Request.assetToUrl(requestedDataType: .emoteBTTVGlobal)
            async let ffzGlobalEmotes = Request.assetToUrl(requestedDataType: .emoteFFZGlobal)
            async let twitchGlobalBadges = Request.assetToUrl(requestedDataType: .badgeTwitchGlobal, token: token)

            let registries = try await [twitchGlobalEmotes, bttvGlobalEmotes, ffzGlobalEmotes, twitchGlobalBadges]
            for registry in registries {
                finalRegisty.merge(registry) {(_, new) in new}
            }
        } catch {
            print("Failed to get global assets: ", error.localizedDescription)
        }
        return finalRegisty
    }

    func getChannelAssets(token: String, id: String) async -> [String: URL] {
        var finalRegisty = [String: URL]()
        do {
            async let twitchChannelEmotes = Request.assetToUrl(requestedDataType: .emoteTwitchChannel(id: id), token: token)
            async let bttvChannelEmotes = Request.assetToUrl(requestedDataType: .emoteBTTVChannel(id: id))
            async let ffzChannelEmotes = Request.assetToUrl(requestedDataType: .emoteFFZChannel(id: id))
            async let twitchChannelBadges = Request.assetToUrl(requestedDataType: .badgeTwitchChannel(id: id), token: token)

            let registries = try await [twitchChannelEmotes, bttvChannelEmotes, ffzChannelEmotes, twitchChannelBadges]
            for registry in registries {
                finalRegisty.merge(registry) {(_, new) in new}
            }
        } catch {
            print("Failed to get channel assets: ", error.localizedDescription)
        }
        return finalRegisty
    }

}

extension String {
    func unescapeIRCTags() -> String {
        return self.replacingOccurrences(of: "\\s", with: " ")
    }
}
