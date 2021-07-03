//
//  ChatViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/5/21.
//

import Foundation
import SwiftUI

// TODO: Add pinging so rooms last more than 5 min
// TODO: Maybe instead of closing ws connection when leaving room, use PART and JOIN for faster connection. Only dc the ws connection when user exits the app

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    static private let websocketURL = URL(string: "wss://irc-ws.chat.twitch.tv:443")!
    static private let session = URLSession.shared
    var chatting: Bool = false
    private let websocket = session.webSocketTask(with: websocketURL)
    
    func start(token: String, user: String, streamer: StreamerInfo) async {
        let PASS = URLSessionWebSocketTask.Message.string("PASS oauth:\(token)")
        let NICKNAME = URLSessionWebSocketTask.Message.string("NICK \(user)")
        let JOIN = URLSessionWebSocketTask.Message.string("JOIN #\(streamer.userLogin)")
        let TAG = URLSessionWebSocketTask.Message.string("CAP REQ :twitch.tv/tags")
        let COMMAND = URLSessionWebSocketTask.Message.string("CAP REQ :twitch.tv/commands")
        let END = URLSessionWebSocketTask.Message.string("CAP END")
        let CAP = URLSessionWebSocketTask.Message.string("CAP LS 302")
        // let PART = URLSessionWebSocketTask.Message.string("PART #\(streamer)")
        
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
        
        // TODO: Make these throw and run concurrently (async let). Perhaps async let and await an array of result?
        await ChatManager.getGlobalEmotes(token: token)
        await ChatManager.getChannelEmotes(token: token, id: streamer.userId)
        
        func recieve() {
            if !chatting {
                print("END CHAT")
                websocket.cancel(with: .goingAway, reason: nil)
//                websocket.send(PART) { error in
//                    if let error = error {
//                        print(error.localizedDescription)
//                        return
//                    }
//                }
                DispatchQueue.main.async {
                    self.messages.removeAll()
                }
                return
            }
            websocket.receive { result in
                switch result {
                case .failure(let error):
                    print(error)
                    let errorMessage = Message(name: "Error", message: "Failed to connect to chat.", tags: [:])
                    self.messages.append(errorMessage)
                case .success(let response):
                    switch response {
                    case .data(let data):
                        print("WS DATA ", data)
                    case .string(let string):
                        if string[string.startIndex] == "@" {
                            DispatchQueue.main.async { [self] in
                                if let parsed = parseMessage(string) {
                                    var newList = messages
                                    newList.append(parsed)
                                    if newList.count > 80 {
                                        print("Removing Messages")
                                        newList.removeFirst(10)
                                    }
                                    messages = newList
                                }
                            }
                        }
                    @unknown default:
                        print("ERROR")
                    }
                    recieve()
                }
            }
        }
        recieve()
    }
    
    // FIXME: Messages will occasionally show tags/not parse correctly, maybe whitespace?
    func parseMessage(_ whole: String) -> Message? {
        let divider = whole.firstIndex(of: " ")!
        let tags = String(whole[...whole.index(before: divider)])
        let message = String(whole[whole.index(after: divider)...])

        let tagSplit = tags.components(separatedBy: ";")
        var mapping: [String:String] = [:]
        for item in tagSplit {
            let split = item.components(separatedBy: "=")
            if split.count > 1 {
                mapping[split[0]] = split[1]
            }
        }
        
        let messageSplit = message.split(separator: " ", maxSplits: 3)
        
        print(messageSplit[1], whole)
        print(mapping)
        
        if messageSplit[1] == "PRIVMSG" {
            let start = messageSplit[0].index(after: messageSplit[0].startIndex)
            let end = messageSplit[0].index(before: messageSplit[0].firstIndex(of: "!")!)

            let name = messageSplit[0][start...end]
            
            let range = messageSplit.last!.index(after: messageSplit.last!.startIndex)..<messageSplit.last!.endIndex
            let userMessage = messageSplit.last![range]
            
            return Message(name: String(name), message: String(userMessage), tags: mapping)
        } else {
            return nil
        }
    }
    
    func sendPing() {
        websocket.sendPing { error in
            if let error = error {
                print("Ping failed: \(error.localizedDescription)")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
                print("SENDING PING...")
                self.sendPing()
            }
        }
    }
    
    // FIXME: Most colors (name) come up as grey?
    func emotify(_ message: Message) -> Text {
        var split = message.message.components(separatedBy: " ")
        split[split.endIndex - 1] = split[split.endIndex - 1].replacingOccurrences(of: "\r\n", with: "")
        
        var result = Text("")
        
        if let badges = message.tags["badges"] {
            for badge in badges.components(separatedBy: ",") {
                if let cachedVersion = Cache.cache.object(forKey: NSString(string: badge)) {
                    let badgeData = Data(referencing: cachedVersion)
                    result = result + Text(Image(uiImage: UIImage(data: badgeData)!)) + Text(" ")
                }
            }
        }
        
        let hexColor = hexStringToUIColor(hex: message.tags["color"]!)
        
        result = result + Text("\(message.name):").bold().foregroundColor(Color(uiColor: hexColor))
        
        var hits: [String:Data] = [:]
        for word in split {
            if let emoteData = hits[word] {
                result = result + Text(" ") + Text(Image(uiImage: UIImage(data: emoteData)!))
            } else if let cachedVersion = Cache.cache.object(forKey: NSString(string: word)) {
                let emoteData = Data(referencing: cachedVersion)
                result = result + Text(" ") + Text(Image(uiImage: UIImage(data: emoteData)!))
                hits[word] = emoteData
            } else {
                result = result + Text(" ") + Text(word)
            }
        }
        return result
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
