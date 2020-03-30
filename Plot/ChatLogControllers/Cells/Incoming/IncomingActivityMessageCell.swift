//
//  IncomingActivityMessageCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/29/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit


class IncomingActivityMessageCell: BaseActivityMessageCell {
    
      let textView: FalconTextView = {
        let textView = FalconTextView()
    //    textView.font = UIFont.systemFont(ofSize: 13)
        textView.font = UIFont.preferredFont(forTextStyle: .callout)
        textView.textColor = .darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
//        textView.textContainerInset = UIEdgeInsets(top: incomingTextViewTopInset, left: incomingTextViewLeftInset, bottom: incomingTextViewBottomInset, right: incomingTextViewRightInset)
        textView.linkTextAttributes = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        return textView
      }()

  var messageImageViewTopAnchor: NSLayoutConstraint!
  
    override func setupViews() {
        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToActivity(_:))))
        bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageImageView)
        bubbleView.addSubview(textView)
        bubbleView.addSubview(nameLabel)
        bubbleView.frame.origin = CGPoint(x: 10, y: 0)
        bubbleView.frame.size.width = 200
        progressView.strokeColor = .black
        bubbleView.image = grayBubbleImage
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 4).isActive = true
//        messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -20).isActive = true
        messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 9).isActive = true
        messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -4).isActive = true
        textView.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 5).isActive = true
        textView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -5).isActive = true
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 12).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -7).isActive = true
        bubbleView.addSubview(progressView)
        progressView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        progressView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 60).isActive = true
  }
  
  func setupData(message: Message, isGroupChat: Bool) {
    self.message = message
    guard let messageText = message.text else { return }
    textView.text = messageText
    bubbleView.frame.size.height = frame.size.height.rounded()
    
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.frame.size.height = 10
      nameLabel.sizeToFit()
      nameLabel.frame.origin = CGPoint(x: BaseMessageCell.incomingTextViewLeftInset+5, y: BaseMessageCell.incomingTextViewTopInset)
      messageImageViewTopAnchor.constant = 34
      if nameLabel.frame.size.width >= 170 {
        nameLabel.frame.size.width = 170
      }
//        textView.textContainerInset.top = 25
        textView.frame.size = CGSize(width: bubbleView.frame.width.rounded(), height: 15)
    } else {
        textView.frame.size = CGSize(width: bubbleView.frame.width.rounded(), height: 15)
    }
    messageImageView.isUserInteractionEnabled = false
    setupTimestampView(message: message, isOutgoing: false)
  }

  override func prepareViewsForReuse() {
     super.prepareViewsForReuse()
    bubbleView.image = grayBubbleImage
    messageImageView.sd_cancelCurrentImageLoad()
    messageImageView.image = nil
    messageImageViewTopAnchor.constant = 4
  }
}
