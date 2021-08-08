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

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var chatBoxMessage: String = ""
    
    private let websocket = URLSession.shared.webSocketTask(with: URL(string: "wss://irc-ws.chat.twitch.tv:443")!)
    
    var chatting: Bool = false
    var assetToUrl: [String:URL] = [:]

    
    func start(token: String, user: String, channelName: String) async {
        let streamer: [User] = await Request.getUser(login: channelName, token: token)
        
        if streamer.isEmpty {
            return
        }
        
        async let globalAssets: [String:URL] = getGlobalAssets(token: token)
        async let channelAssets: [String:URL] = getChannelAssets(token: token, id: streamer.first!.id)
        
        let assetsToUrl = await [globalAssets, channelAssets]
        
        for registry in assetsToUrl {
            assetToUrl.merge(registry) {(_,new) in new}
        }
                
        print("Starting chat!")
        
        let PASS = URLSessionWebSocketTask.Message.string("PASS oauth:\(token)")
        let NICKNAME = URLSessionWebSocketTask.Message.string("NICK \(user)")
        let JOIN = URLSessionWebSocketTask.Message.string("JOIN #\(channelName.lowercased())")
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
                            if let parsed = self.buildMessage(string) {
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
        let message = whole[whole.index(after: tagAndMessageDivider)...] //substring 2
        
        var mappedTags = [String:String]()

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
            let chatMessage = splitMessage[3].dropFirst().dropLast()
//            print(mappedTags)
//            print(chatMesssage)
            if let emoteTags = mappedTags["emotes"] {
                let emotes = emoteTags.split(separator: "/")
                emotes.forEach { emote in
                    // Get the split
                    let indexBetweenIdAndPositions = emote.firstIndex(of: ":")!
                    
                    let range: Substring
                    // Get the index of the emote in the message
                    // If there are multiple, get the first one
                    if let endOfFirstEmotePosition = emote.firstIndex(of: ",") {
                        // Get the index position of the emote and convert it to int
                        range = emote[emote.index(after: indexBetweenIdAndPositions)..<endOfFirstEmotePosition]
                    } else {
                        range = emote[emote.index(after: indexBetweenIdAndPositions)..<emote.endIndex]
                    }
                    
                    let indexSplit = range.split(separator: "-")
                    let startIndex = Int(indexSplit[0])!
                    let endIndex = Int(indexSplit[1])!
                    
                    // Convert the int index to index
                    let start = chatMessage.index(chatMessage.startIndex ,offsetBy: startIndex)
                    let end = chatMessage.index(start, offsetBy: endIndex-startIndex)
                    print(chatMessage)
                    // Slice the word
                    let emoteWord = String(chatMessage[start...end])
                    print(emoteWord)
                    // Get the ID
                    let emoteId = emote[..<indexBetweenIdAndPositions]
                    
                    assetToUrl[emoteWord] = URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(emoteId)/default/dark/3.0")!
                }
                // print(chatMessage, emotes)
            }
            return Message(tags: mappedTags, type: .PRIVMSG, message: String(chatMessage))
        }
        return nil
    }
    
    func getGlobalAssets(token: String) async -> [String:URL] {
        var finalRegisty: [String:URL] = [:]

        do {
            async let twitchGlobalEmotes = Request.assetToUrl(requestedDataType: .emoteTwitchGlobal, token: token)
            async let bttvGlobalEmotes = Request.assetToUrl(requestedDataType: .emoteBTTVGlobal)
            async let ffzGlobalEmotes = Request.assetToUrl(requestedDataType: .emoteFFZGlobal)
            async let twitchGlobalBadges = Request.assetToUrl(requestedDataType: .badgeTwitchGlobal, token: token)
            
            let registries = try await [twitchGlobalEmotes, bttvGlobalEmotes, ffzGlobalEmotes, twitchGlobalBadges]
            for registry in registries {
                finalRegisty.merge(registry) {(_,new) in new}
            }
        } catch {
            print("Failed to get global assets: ", error.localizedDescription)
        }
        return finalRegisty
    }
    
    func getChannelAssets(token: String, id: String) async -> [String:URL] {
        var finalRegisty: [String:URL] = [:]
        do {
            async let twitchChannelEmotes = Request.assetToUrl(requestedDataType: .emoteTwitchChannel(id: id), token: token)
            async let bttvChannelEmotes = Request.assetToUrl(requestedDataType: .emoteBTTVChannel(id: id))
            async let ffzChannelEmotes = Request.assetToUrl(requestedDataType: .emoteFFZChannel(id: id))
            async let twitchChannelBadges = Request.assetToUrl(requestedDataType: .badgeTwitchChannel(id: id), token: token)
            
            let registries = try await [twitchChannelEmotes, bttvChannelEmotes, ffzChannelEmotes, twitchChannelBadges]
            for registry in registries {
                finalRegisty.merge(registry) {(_,new) in new}
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

class FlexMessageView: UIView {
    private let rootFlexContainer = UIView()
    private var size: CGSize?
    private var height: CGFloat = 0
    
    init(message: Message, assetToUrl: [String:URL], size: CGSize) {
        super.init(frame: .zero)
        self.size = size
        addSubview(rootFlexContainer)
        
        var badgeImageOptions = ImageLoadingOptions(
            placeholder: UIImage(systemName: "circle")!
        )
        badgeImageOptions.processors = [ImageProcessors.Resize(height: 50, unit: .pixels, upscale: true)]
        
        var emoteImageOptions = ImageLoadingOptions(
            placeholder: UIImage(systemName: "circle")!
        )
        emoteImageOptions.processors = [ImageProcessors.Resize(height: 80, unit: .pixels, upscale: true)]
        
        let words = message.message.components(separatedBy: " ")

        rootFlexContainer.flex.direction(.row).wrap(.wrap).alignItems(.center).define { flex in
            
            // 1. Add chat badges if any.
            if let badges = message.tags["badges"] {
                for badge in badges.components(separatedBy: ",") {
                    if let badgeUrl = assetToUrl[badge] {
                        let badgeImageView = UIImageView()
                        Nuke.loadImage(with: badgeUrl, options:badgeImageOptions, into: badgeImageView)
                        flex.addItem(badgeImageView)
                    }
                }
            }
            
            // 2. Add the user's name
            let nameView = UILabel()
            nameView.font = UIFont.preferredFont(forTextStyle: .footnote)
            nameView.font = UIFont.boldSystemFont(ofSize: nameView.font.pointSize)
            nameView.text = message.tags["display-name"]?.appending(": ")
            nameView.textColor = hexStringToUIColor(hex: message.tags["color"] ?? "#868686")
            nameView.numberOfLines = 0
            flex.addItem(nameView)
            
            // 3. Add the message words and emotes if any
            for word in words {
                // 3.1. If emote exists, add it
                if let emoteUrl = assetToUrl[word] {
                    let emoteImageView = GIFImageView()
                    Nuke.loadImage(with: emoteUrl, options: emoteImageOptions, into: emoteImageView)
                    flex.addItem(emoteImageView)
                
                // 3.2. If word exists, add it
                } else {
                    // Maybe use one UILabel instead of re-creating
                    let wordView = UILabel()
                    wordView.font = UIFont.preferredFont(forTextStyle: .footnote)
                    wordView.text = word
                    wordView.numberOfLines = 0
                    flex.addItem(wordView)
                }
                // 3.3. Append a space at the end of each image or word
                let spaceView = UILabel()
                spaceView.font = UIFont.preferredFont(forTextStyle: .footnote)
                spaceView.text = " "
                spaceView.numberOfLines = 0
                flex.addItem(spaceView)
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

struct FlexMessage: UIViewRepresentable {
    let message: Message
    let assetToUrl: [String:URL]
    let size: CGSize
        
    typealias UIViewControllerType = UIView
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    func makeUIView(context: Context) -> UIView {
        let newView = FlexMessageView(message: message, assetToUrl: assetToUrl, size: size)
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
        prepareForReuse()
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
