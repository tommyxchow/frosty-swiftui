//
//  ChatViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/5/21.
//

import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [[String]] = []
    static private let websocketURL = URL(string: "wss://irc-ws.chat.twitch.tv:443")!
    static private let session = URLSession.shared
    
    var chatting: Bool = false
    
    let websocket = session.webSocketTask(with: websocketURL)
    
    func start(token: String, user: String, streamer: String) {
        let PASS = URLSessionWebSocketTask.Message.string("PASS oauth:\(token)")
        let NICKNAME = URLSessionWebSocketTask.Message.string("NICK \(user)")
        let JOIN = URLSessionWebSocketTask.Message.string("JOIN #\(streamer)")
//        let TAG = URLSessionWebSocketTask.Message.string("CAP REQ :twitch.tv/tags")
//        let COMMAND = URLSessionWebSocketTask.Message.string("CAP REQ :twitch.tv/commands")
//        let END = URLSessionWebSocketTask.Message.string("CAP END")
//        let CAP = URLSessionWebSocketTask.Message.string("CAP LS 302")
//        let PART = URLSessionWebSocketTask.Message.string("PART #\(streamer)")
        
        let commands = [PASS, NICKNAME, JOIN]
        
        websocket.resume()
        
        chatting = true
        
        for command in commands {
            websocket.send(command) { error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
            }
        }
        
        var count = 0
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
                case.failure(let error):
                    print(error)
                case.success(let response):
                    switch response {
                    case .data(let data):
                        print(data)
                    case .string(let string):
                        if count == 3 {
                            DispatchQueue.main.async { [self] in
                                print(string)
                                messages.append(parseMessage(string))
//                                if messages.count > 60 {
//                                    messages.removeFirst(10)
//                                }
                            }
                        } else {
                            count += 1
                            print(string)
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
    
    func parseMessage(_ string: String) -> [String] {
        let split = string.split(separator: " ", maxSplits: 3)

        let start = split[0].index(after: split[0].startIndex)
        let end = split[0].index(before: split[0].firstIndex(of: "!")!)

        let name = split[0][start...end]
        
        let range = split.last!.index(after: split.last!.startIndex)..<split.last!.endIndex
        let message = split.last![range]
        
        return [String(name), String(message), UUID().uuidString]
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
    
    func emoteMessage(_ pair: [String]) -> some View {
        var split = pair[1].components(separatedBy: " ")
        split[split.endIndex - 1] = split[split.endIndex - 1].replacingOccurrences(of: "\r\n", with: "")
        
        var result = Text("\(pair[0]):").bold()
        
        for word in split {
            if word == "OMEGALUL" {
                result = result + Text(" ") + Text(Image("OMEGALUL")).baselineOffset(-8)
            } else {
                result = result + Text(" ") + Text(word)
            }
        }
        
        return result
    }
}
