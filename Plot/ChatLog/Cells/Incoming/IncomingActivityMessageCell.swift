//
//  IncomingActivityMessageCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/29/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit


class IncomingActivityMessageCell: BaseActivityMessageCell {
    
    let textView: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkText
        label.numberOfLines = 0
        return label
    }()

    let categoryView: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkText
        label.numberOfLines = 0
        return label
    }()

    let subcategoryView: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkText
        label.numberOfLines = 0
        return label
    }()

  var messageImageViewTopAnchor: NSLayoutConstraint!
  
    override func setupViews() {
        messageImageView.constrainHeight(175)
        
        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToActivity(_:))))
        bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
        contentView.addSubview(nameLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageImageView)
        bubbleView.addSubview(textView)
        bubbleView.addSubview(categoryView)
        bubbleView.addSubview(subcategoryView)
        bubbleView.frame.origin = CGPoint(x: 10, y: 30)
        bubbleView.frame.size.width = 230
        progressView.strokeColor = .black
        bubbleView.image = grayBubbleImage
        
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -1).isActive = true
        
//        messageImageViewTopAnchor = messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0)
//        messageImageViewTopAnchor.isActive = true
        messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 4.8).isActive = true
        messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: 0).isActive = true
        textView.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 10).isActive = true
//        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 12).isActive = true
//        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -7).isActive = true
        
//           messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -1).isActive = true
//           messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 0).isActive = true
//           messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -4.8).isActive = true

           textView.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 10).isActive = true
           textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 15).isActive = true
           textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -5).isActive = true

           categoryView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 2).isActive = true
           categoryView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 15).isActive = true
           categoryView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -5).isActive = true

           subcategoryView.topAnchor.constraint(equalTo: categoryView.bottomAnchor, constant: 2).isActive = true
           subcategoryView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 15).isActive = true
           subcategoryView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -5).isActive = true
        
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
    if let categoryText = message.activityCategory, categoryText != "" {
        categoryView.text = categoryText
    }
    if let subcategoryText = message.activitySubcategory, subcategoryText != "" {
        subcategoryView.text = subcategoryText
    }
    
    bubbleView.frame.size.height = frame.size.height.rounded() - 35
    
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.frame.size.height = 10
      nameLabel.sizeToFit()
      nameLabel.frame.origin = CGPoint(x: BaseMessageCell.incomingTextViewLeftInset+5, y: BaseMessageCell.incomingTextViewTopInset)
    }
    messageImageView.isUserInteractionEnabled = false
    setupTimestampView(message: message, isOutgoing: false)
  }

  override func prepareViewsForReuse() {
     super.prepareViewsForReuse()
    bubbleView.image = grayBubbleImage
    messageImageView.sd_cancelCurrentImageLoad()
    messageImageView.image = nil
//    messageImageViewTopAnchor.constant = 4
    categoryView.text = ""
    subcategoryView.text = ""
  }
}
