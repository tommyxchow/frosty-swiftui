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
import FLAnimatedImage
import Gifu

// TODO: Maybe instead of closing ws connection when leaving room, use PART and JOIN for faster connection. Only dc the ws connection when user exits the app

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = [Message(name: "STATUS", message: "Connecting to chat...", tags: ["color":"#00FF00"])]
    private let websocket = URLSession.shared.webSocketTask(with: URL(string: "wss://irc-ws.chat.twitch.tv:443")!)
    var chatting: Bool = false
    var assetToUrl: [String:URL] = [:]

    
    func start(token: String, user: String, streamer: StreamerInfo) async {
        async let globalAssets: [String:URL] = ChatManager.getGlobalAssets(token: token)
        async let channelAssets: [String:URL] = ChatManager.getChannelAssets(token: token, id: streamer.userId)
        
        let assetsToUrl = await [globalAssets, channelAssets]
        
        for registry in assetsToUrl {
            assetToUrl.merge(registry) {(_,new) in new}
        }
                
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
                                if newList.count > 80 {
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

        var testReg: [String] = []

        var split = message.message.components(separatedBy: " ")
        split[split.endIndex - 1] = split[split.endIndex - 1].replacingOccurrences(of: "\r\n", with: "")
        
        
        if let badges = message.tags["badges"] {
            for badge in badges.components(separatedBy: ",") {
                if let url = assetToUrl[badge] {
                    testReg.append("}"+url.absoluteString)
                }
            }
        }
        
        testReg.append(message.name + ": ")
        
        for word in split {
            if let url = assetToUrl[word] {
                testReg.append("}"+url.absoluteString)
            } else {
                testReg.append(word + " ")
            }
        }
        // print(testReg)
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

class FlexMessageView: UIView {
    private let rootFlexContainer = UIView()
    private var size: CGSize?
    private var height: CGFloat = 0
    
    init(words: [String], size: CGSize) {
        super.init(frame: .zero)
        self.size = size
        addSubview(rootFlexContainer)
        
        var imageOptions = ImageLoadingOptions(
            placeholder: UIImage(systemName: "circle")!
        )
                            
        imageOptions.processors = [ImageProcessors.Resize(height: 20)]
        
        rootFlexContainer.flex.direction(.row).wrap(.wrap).alignItems(.center).define { flex in
            for word in words {
                if word.starts(with: "}") {
                    
                    let url = URL(string: word.replacingOccurrences(of: "}", with: ""))!

                    let imageView = GIFImageView()
                    
                    Nuke.loadImage(with: url, options: imageOptions, into: imageView)
                    
                    flex.addItem(imageView)
                    
                } else {
                    let labelView = UILabel()
                    labelView.font = UIFont.preferredFont(forTextStyle: .footnote)
                    labelView.text = word
                    flex.addItem(labelView)
                    
                }
            }
        }
        let lines = ceil(rootFlexContainer.flex.intrinsicSize.width / size.width)
        height = lines * rootFlexContainer.flex.intrinsicSize.height
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {

        super.layoutSubviews()
        
        rootFlexContainer.frame = CGRect(x: 0, y: 0, width: size!.width, height: 0)
        rootFlexContainer.flex.layout(mode: .adjustHeight)
                
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: size!.width, height: height)
    }
    

}

struct FlexMessage: UIViewRepresentable {
    let words: [String]
    let size: CGSize
        
    typealias UIViewControllerType = UIView
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    func makeUIView(context: Context) -> UIView {
        let newView = FlexMessageView(words: words, size: size)
        newView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return newView
    }
    
}


extension GIFImageView {
    open override func nuke_display(image: UIImage?, data: Data?) {
        guard image != nil else {
            self.image = nil
            return
        }
        if let data = data {
            // Display poster image immediately
            self.image = image

            // Prepare FLAnimatedImage object asynchronously (it takes a
            // noticeable amount of time), and start playback.
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    // If view is still displaying the same image
                    if self.image === image {
                        self.animate(withGIFData: data)
                    }
                }
            }
        } else {
            self.image = image
        }
    }
}
