//
//  OutgoingActivityMessageCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/29/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class OutgoingActivityMessageCell: BaseActivityMessageCell {
    
    let textView: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    let categoryView: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    let subcategoryView: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

  override func setupViews() {
    messageImageView.constrainHeight(constant: 175)
    bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToActivity(_:))))
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))))
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(messageImageView)
    bubbleView.addSubview(textView)
    bubbleView.addSubview(categoryView)
    bubbleView.addSubview(subcategoryView)
    bubbleView.image = blueBubbleImage
    progressView.strokeColor = .white
    
    contentView.addSubview(deliveryStatus)
    messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -1).isActive = true
    messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 0).isActive = true
    messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -4.7).isActive = true
 
    textView.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 10).isActive = true
    textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 10).isActive = true
    textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -5).isActive = true

    categoryView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 2).isActive = true
    categoryView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 10).isActive = true
    categoryView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -5).isActive = true
    
    subcategoryView.topAnchor.constraint(equalTo: categoryView.bottomAnchor, constant: 2).isActive = true
    subcategoryView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 10).isActive = true
    subcategoryView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -5).isActive = true

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
    if let categoryText = message.activityCategory, categoryText != "" {
        categoryView.text = categoryText
    }
    if let subcategoryText = message.activitySubcategory, subcategoryText != "" {
        subcategoryView.text = subcategoryText
    }
    
    let frameWidth: CGFloat = 200
    bubbleView.frame = CGRect(x: frame.width - frameWidth - 40, y: 0,
        width: frameWidth + 30, height: frame.size.height.rounded()).integral
    
    setupTimestampView(message: message, isOutgoing: true)
    messageImageView.isUserInteractionEnabled = false
  }

  override func prepareViewsForReuse() {
     super.prepareViewsForReuse()
    bubbleView.image = blueBubbleImage
    messageImageView.sd_cancelCurrentImageLoad()
    messageImageView.image = nil
    categoryView.text = ""
    subcategoryView.text = ""
  }
}
