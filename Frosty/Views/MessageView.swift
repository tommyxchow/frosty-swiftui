//
//  MessageView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/15/21.
//

import SwiftUI
import FlexLayout
import Nuke
import FLAnimatedImage
import NukeBuilder

struct MessageView: View {
    @ObservedObject var viewModel: ChatViewModel
    let message: [String]
    let size: CGSize
        
    var body: some View {
        FlexMessage(words: message, size: size)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(viewModel: ChatViewModel(), message: ["test"], size: .zero)
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
        
        rootFlexContainer.flex.direction(.row).wrap(.wrap).alignItems(.center).define { flex in
            for word in words {
                if word.starts(with: "}") {
                    
                    let url = URL(string: word.replacingOccurrences(of: "}", with: ""))!

                    let imageView = FLAnimatedImageView()

                    let image = ImagePipeline.shared.image(with: url)
                        .resize(height: 20)
                                            
                    image.display(in: imageView)
                        .placeholder(UIImage(systemName: "square.fill")!)
                        .load()
                    
                    flex.addItem().define { item in
                        flex.addItem(imageView)
                    }
                    
                } else {
                    let labelView = UILabel()
                    labelView.font = UIFont.preferredFont(forTextStyle: .footnote)
                    labelView.text = word
                    flex.addItem().define { item in
                        flex.addItem(labelView)
                    }
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


