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
    @Published var messages: [Message] = [Message(name: "STATUS", message: "Connecting to chat...", tags: ["color":"#00FF00"])]
    private let websocket = URLSession.shared.webSocketTask(with: URL(string: "wss://irc-ws.chat.twitch.tv:443")!)
    var chatting: Bool = false
    var assetToUrl: [String:URL] = [:]

    
    func start(token: String, user: String, streamer: StreamerInfo) async {
        // TODO: Make these throw and run concurrently (async let). Perhaps async let and await an array of result?
        
        async let globalAssets: [String:URL] = ChatManager.getGlobalAssets(token: token)
        async let channelAssets: [String:URL] = ChatManager.getChannelAssets(token: token, id: streamer.userId)
        
        let assetsToUrl = await [globalAssets, channelAssets]
        
        for registry in assetsToUrl {
            assetToUrl.merge(registry) {(_,new) in new}
        }
        
        print(assetToUrl)
        print("Starting chat!")
        
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
        
        DispatchQueue.main.async {
            self.messages.append(Message(name: "STATUS", message: "Connected!", tags: ["color":"#00FF00"]))
            self.messages.append(Message(name: "STATUS", message: "Welcome to \(streamer.userName)'s chat!", tags: ["color":"#00FF00"]))
        }
        
        receive()
    }
    
    func receive() {
        websocket.receive { result in
            switch result {
            case .failure(let error):
                print(error)
                let errorMessage = Message(name: "ERROR", message: "Failed to connect to chat.", tags: ["color":"#FF0000"])
                DispatchQueue.main.async {
                    self.messages.append(errorMessage)
                }
            case .success(let response):
                switch response {
                case .data(let data):
                    print("WS DATA ", data)
                case .string(let string):
                    //print(string)
                    if string[string.startIndex] == "P" {
                        let message = URLSessionWebSocketTask.Message.string("PONG :tmi.twitch.tv")
                        self.websocket.send(message) { error in
                            if let error = error {
                                print("Failed to send PONG: \(error)")
                            }
                        }
                    }
                    if string[string.startIndex] == "@" {
                        DispatchQueue.main.async {
                            if let parsed = self.parseMessage(string) {
                                var newList = self.messages
                                newList.append(parsed)
                                if newList.count > 30 {
                                    newList.removeFirst(10)
                                }
                                self.messages = newList
                            }
                        }
                    }
                @unknown default:
                    print("ERROR")
                }
                if self.chatting {
                    self.receive()
                }
            }
        }
    }
    
    func end() {
        print("Ending chat")
        websocket.cancel(with: .goingAway, reason: nil)
        messages.removeAll()
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
        
//        print(messageSplit[1], whole)
//        print(mapping)
        
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
    
    func beautify(_ message: Message) -> [String] {
//        if message.name == "STATUS" {
//            return Text(message.message)
//        }
        var testReg: [String] = []

        var split = message.message.components(separatedBy: " ")
        split[split.endIndex - 1] = split[split.endIndex - 1].replacingOccurrences(of: "\r\n", with: "")
        
        var result = Text("")
        
        if let badges = message.tags["badges"] {
            for badge in badges.components(separatedBy: ",") {
                if let url = assetToUrl[badge] {
                    testReg.append("}"+url.absoluteString)
                }
            }
        }
        
        testReg.append(message.name)
        testReg.append(": ")
        
        var hexColor = hexStringToUIColor(hex: "#737373")
        
        if let color = message.tags["color"] {
            hexColor = hexStringToUIColor(hex: color)
        }
        
        result = result + Text("\(message.name):").bold().foregroundColor(Color(uiColor: hexColor)) + Text(" ")
        
        for word in split {
            if let url = assetToUrl[word] {
                testReg.append("}"+url.absoluteString)
            } else {
                testReg.append(word + " ")
                result = result + Text(" ") + Text(word)
            }
        }
        //print(testReg)
        return testReg
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
