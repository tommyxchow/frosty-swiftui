//
//  ChatFlexMessageView.swift
//  ChatFlexMessageView
//
//  Created by Tommy Chow on 8/8/21.
//

import Foundation
import SwiftUI
import Nuke
import Gifu
import Kingfisher

class FlexMessageView: UIView {
    private let rootFlexContainer = UIView()
    private var size: CGSize?
    private var height: CGFloat = 0

    init(message: Message, assetToUrl: [String: URL], size: CGSize) {
        super.init(frame: .zero)
        self.size = size
        addSubview(rootFlexContainer)

        var badgeImageOptions = ImageLoadingOptions(
            placeholder: UIImage(systemName: "circle")!
        )
        badgeImageOptions.processors = [ImageProcessors.Resize(height: 20, upscale: true)]

        var emoteImageOptions = ImageLoadingOptions(
            placeholder: UIImage(systemName: "circle")!
        )
        emoteImageOptions.processors = [ImageProcessors.Resize(height: 30, upscale: true)]

        let words = message.message.components(separatedBy: " ")

        rootFlexContainer.flex.direction(.row).wrap(.wrap).alignItems(.center).define { flex in

            // 1. Add chat badges if any.
            if let badges = message.tags["badges"] {
                for badge in badges.components(separatedBy: ",") {
                    if let badgeUrl = assetToUrl[badge] {
                        let badgeImageView = UIImageView()
                        Nuke.loadImage(with: badgeUrl, options: badgeImageOptions, into: badgeImageView)
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

    func hexStringToUIColor (hex: String) -> UIColor {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if cString.count != 6 {
            return UIColor.gray
        }

        var rgbValue: UInt64 = 0
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
    let assetToUrl: [String: URL]
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
