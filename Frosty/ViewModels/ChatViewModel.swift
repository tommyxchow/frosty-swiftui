//
//  ChatViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/5/21.
//

import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [[String:String]] = []
    static let twitchURL = URL(string: "wss://irc-ws.chat.twitch.tv:443")!
    static let session = URLSession.shared
    
    let PASS = URLSessionWebSocketTask.Message.string("PASS oauth:")
    let NICKNAME = URLSessionWebSocketTask.Message.string("NICK ")
    let JOIN = URLSessionWebSocketTask.Message.string("JOIN #xqcow")
    
    var chatting: Bool = false
    
    let websocket = session.webSocketTask(with: twitchURL)
    
    func start() {
        websocket.resume()
        
        chatting = true
        
        websocket.send(PASS) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }

        websocket.send(NICKNAME) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }

        websocket.send(JOIN) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
        var count = 0
        func recieve() {
            if !chatting {
                websocket.cancel(with: .goingAway, reason: nil)
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
                            DispatchQueue.main.async {
                                print(string)
                                self.messages.append(self.parseMessage(string))
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
    
    func parseMessage(_ string: String) -> [String:String] {
        let split = string.split(separator: " ", maxSplits: 3)

        let start = split[0].index(after: split[0].startIndex)
        let end = split[0].index(before: split[0].firstIndex(of: "!")!)

        let name = split[0][start...end]
        
        let range = split.last!.index(after: split.last!.startIndex)..<split.last!.endIndex
        let message = split.last![range]
        
        return ["\(name)":"\(message)"]
    }
    
    func end() {
        chatting = false
    }
    
    func sendPing() {
        websocket.sendPing { error in
            if let error = error {
                print("Ping failed: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                print("SENDING PING...")
                self.sendPing()
            }
        }
    }
    
    func emoteMessage(_ pair: [String:String]) -> some View {
        var split = pair.first!.value.components(separatedBy: " ")
        split[split.endIndex - 1] = split[split.endIndex - 1].replacingOccurrences(of: "\r\n", with: "")

        
        var result = Text("\(pair.first!.key):").bold()
        print(split)
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
