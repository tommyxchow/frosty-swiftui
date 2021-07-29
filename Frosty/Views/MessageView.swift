//
//  MessageView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/15/21.
//

import SwiftUI
import SDWebImageSwiftUI

struct MessageView: View {
    @ObservedObject var viewModel: ChatViewModel
    let message: [String]
        
    var body: some View {
        FlexTest(words: message)
            .padding(1)
//        WrappingHStack(id: \.self, alignment: .leading) {
//            ForEach(message, id: \.self) { item in
//                if item.starts(with: "}") {
//                    let url = item.replacingOccurrences(of: "}", with: "")
//                    if let gif = ChatManager.emoteToImage[url] {
//                        gif
//                            .frame(height: 25)
//                    } else {
//                        let newImage = WebImage(url: URL(string: url)!)
//                        newImage
//                            .frame(height: 25)
//                            .task {
//                                ChatManager.emoteToImage[url] = newImage
//                            }
//                    }
//                } else {
//                    if let text = ChatManager.dictionary[item] {
//                        text
//                    } else {
//                        let newText = Text(item)
//                        newText
//                            .task {
//                                ChatManager.dictionary[item] = newText
//                            }
//                    }
//                }
//            }
//        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(viewModel: ChatViewModel(), message: ["test"])
    }
}

class FlexView: UIView {
    private let rootFlexContainer = UIView()
    var height: CGFloat = 0
    
    init(words: [String]) {
        super.init(frame: .zero)
        addSubview(rootFlexContainer)
        print(words)
        print(Array("hello"))

                
        rootFlexContainer.flex.direction(.row).wrap(.wrap).define { flex in
            for word in words {
                if word.starts(with: "}") {
                    let imageView = UIImageView()
                    imageView.sd_setImage(with: URL(string: word.replacingOccurrences(of: "}", with: "")))
                    
                    flex.addItem(imageView)
                } else {
                    let labelView = UILabel()
                    labelView.text = word
                    labelView.font = UIFont.preferredFont(forTextStyle: .footnote)
                    labelView.adjustsFontForContentSizeCategory = true
                    flex.addItem(labelView)
                }
            }
        }
        
        let lines = ceil(rootFlexContainer.flex.intrinsicSize.width / 390)
        height = lines * rootFlexContainer.flex.intrinsicSize.height
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {

        super.layoutSubviews()

        rootFlexContainer.frame = CGRect(x: 0, y: 0, width: 390, height: height)
        rootFlexContainer.flex.layout(mode: .adjustHeight)
        
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}

struct FlexTest: UIViewRepresentable {
    let words: [String]
        
    typealias UIViewControllerType = UIView
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    func makeUIView(context: Context) -> UIView {
        let newView = FlexView(words: words)
        newView.setContentHuggingPriority(.required, for: .vertical)
        return newView
    }
    
}

