//
//  OutgoingTextMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class OutgoingTextMessageCell: BaseMessageCell {
  
  let textView: FalconTextView = {
    let textView = FalconTextView()
//    textView.font = UIFont.systemFont(ofSize: 13)
    textView.font = UIFont.preferredFont(forTextStyle: .callout)
    textView.backgroundColor = .clear
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = UIEdgeInsets(top: outgoingTextViewTopInset, left: outgoingTextViewLeftInset, bottom: outgoingTextViewBottomInset, right: outgoingTextViewRightInset)
    textView.dataDetectorTypes = .all
    textView.textColor = .white
    textView.linkTextAttributes = [
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
    ]

    return textView
  }()

  func setupData(message: Message) {
    self.message = message
    guard let messageText = message.text else { return }
    textView.text = messageText
    bubbleView.frame = CGRect(x: frame.width - message.estimatedFrameForText!.width - 40, y: 0,
                                   width: message.estimatedFrameForText!.width + 30, height: frame.size.height).integral
    textView.frame.size = CGSize(width: bubbleView.frame.width.rounded(), height: bubbleView.frame.height.rounded())
    setupTimestampView(message: message, isOutgoing: true)
  }
  
  override func setupViews() {
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(textView)
    contentView.addSubview(deliveryStatus)
    bubbleView.image = blueBubbleImage
  }

  override func prepareViewsForReuse() {
     bubbleView.image = blueBubbleImage
  }
}
