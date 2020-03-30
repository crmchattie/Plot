//
//  OutgoingActivityMessageCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/29/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class OutgoingActivityMessageCell: BaseActivityMessageCell {
    
      let textView: FalconTextView = {
        let textView = FalconTextView()
        textView.font = UIFont.preferredFont(forTextStyle: .callout)
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
//      textView.textContainerInset = UIEdgeInsets(top: outgoingTextViewTopInset, left: outgoingTextViewLeftInset, bottom: outgoingTextViewBottomInset, right: outgoingTextViewRightInset)
        textView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        textView.dataDetectorTypes = .all
        textView.textColor = .white

        return textView
      }()

  override func setupViews() {
    bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToActivity(_:))))
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))))
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(messageImageView)
    bubbleView.addSubview(textView)
    bubbleView.image = blueBubbleImage
    progressView.strokeColor = .white

    contentView.addSubview(deliveryStatus)
    messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0).isActive = true
    messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -30).isActive = true
    messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 0).isActive = true
    messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -4).isActive = true
    textView.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: -3).isActive = true
//    textView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -5).isActive = true
//    textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 12).isActive = true
//    textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -7).isActive = true
    textView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true

    bubbleView.addSubview(progressView)
    progressView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    progressView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    progressView.widthAnchor.constraint(equalToConstant: 60).isActive = true
    progressView.heightAnchor.constraint(equalToConstant: 60).isActive = true
  }

  func setupData(message: Message) {
    self.message = message
    guard let messageText = message.text else { return }
    textView.text = messageText
    bubbleView.frame = CGRect(x: frame.width - message.estimatedFrameForText!.width - 40, y: 0,
    width: message.estimatedFrameForText!.width + 30, height: frame.size.height.rounded()).integral
//    bubbleView.frame.origin = CGPoint(x: (frame.width - 210).rounded(), y: 0)
//    bubbleView.frame.size.height = frame.size.height.rounded()
    textView.frame.size = CGSize(width: bubbleView.frame.width.rounded(), height: message.estimatedFrameForText!.height + 30)
    
    setupTimestampView(message: message, isOutgoing: true)
    messageImageView.isUserInteractionEnabled = false
  }

  override func prepareViewsForReuse() {
     super.prepareViewsForReuse()
    bubbleView.image = blueBubbleImage
    messageImageView.sd_cancelCurrentImageLoad()
    messageImageView.image = nil
  }
}
