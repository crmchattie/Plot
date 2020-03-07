//
//  BaseMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class BaseMessageCell: RevealableCollectionViewCell {
  
  weak var message: Message?
  weak var chatLogController: ChatLogController?
  
  let grayBubbleImage = ThemeManager.currentTheme().incomingBubble
  let blueBubbleImage = ThemeManager.currentTheme().outgoingBubble
	static let selectedOutgoingBubble = UIImage(named: "OutgoingSelected")!.resizableImage(withCapInsets: UIEdgeInsets(top: 14,
																																																										 left: 14,
																																																										 bottom: 17,
																																																										 right: 28))
	static let selectedIncomingBubble = UIImage(named: "IncomingSelected")!.resizableImage(withCapInsets: UIEdgeInsets(top: 14,
																																																										 left: 22,
																																																										 bottom: 17,
																																																										 right: 20))
  
  static let incomingTextViewTopInset: CGFloat = 10
  static let incomingTextViewBottomInset: CGFloat = 0
  static let incomingTextViewLeftInset: CGFloat = 12
  static let incomingTextViewRightInset: CGFloat = 7
    
  static let outgoingTextViewTopInset: CGFloat = 10
  static let outgoingTextViewBottomInset: CGFloat = 0
  static let outgoingTextViewLeftInset: CGFloat = 7
  static let outgoingTextViewRightInset: CGFloat = 7
  
    
  let bubbleView: UIImageView = {
    let bubbleView = UIImageView()
    bubbleView.backgroundColor = ThemeManager.currentTheme().chatBackgroundColor
    bubbleView.isUserInteractionEnabled = true
    
    return bubbleView
  }()
  
  //text message delivery status interface
  var deliveryStatus: UILabel = {
    var deliveryStatus = UILabel()
    deliveryStatus.text = "status"
//    deliveryStatus.font = UIFont.boldSystemFont(ofSize: 10)
    deliveryStatus.font = UIFont.preferredFont(forTextStyle: .caption2)
    deliveryStatus.adjustsFontForContentSizeCategory = true
    deliveryStatus.minimumScaleFactor = 0.1
    deliveryStatus.adjustsFontSizeToFitWidth = true
    deliveryStatus.textColor =  ThemeManager.currentTheme().generalSubtitleColor
    deliveryStatus.isHidden = true
    deliveryStatus.textAlignment = .right
    
    return deliveryStatus
  }()
    
  //user name label interface
  let nameLabel: UILabel = {
    let nameLabel = UILabel()
//    nameLabel.font = UIFont.systemFont(ofSize: 13)
    nameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    nameLabel.adjustsFontForContentSizeCategory = true
    nameLabel.minimumScaleFactor = 0.1
    nameLabel.adjustsFontSizeToFitWidth = true
    nameLabel.numberOfLines = 1
    nameLabel.backgroundColor = .clear
    nameLabel.textColor = FalconPalette.defaultBlue
    
    return nameLabel
  }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame.integral)
    
    setupViews()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureDeliveryStatus(at indexPath: IndexPath, lastMessageIndex: Int, message: Message) {
    switch indexPath.row == lastMessageIndex {
    case true:
      DispatchQueue.main.async {
        self.deliveryStatus.frame = CGRect(x: self.frame.width - 80, y: self.bubbleView.frame.height + 2, width: 70, height: 10).integral
        self.deliveryStatus.text = message.status
        self.deliveryStatus.isHidden = false
        self.deliveryStatus.layoutIfNeeded()
      }
      break
      
    default:
      DispatchQueue.main.async {
        self.deliveryStatus.isHidden = true
        self.deliveryStatus.layoutIfNeeded()
      }
      break
    }
  }
  
  func setupTimestampView(message: Message, isOutgoing: Bool) {
    DispatchQueue.main.async {
      let view = self.chatLogController?.collectionView?.dequeueReusableRevealableView(withIdentifier: "timestamp") as? TimestampView ?? TimestampView()
      view.titleLabel.text = message.convertedTimestamp
      let style: RevealStyle = isOutgoing ? .slide : .over
      self.setRevealableView(view, style: style, direction: .left)
    }
  }

  func setupViews() {
    backgroundColor = ThemeManager.currentTheme().chatBackgroundColor
    contentView.backgroundColor = ThemeManager.currentTheme().chatBackgroundColor
  }

  func prepareViewsForReuse() {}

  override func prepareForReuse() {
    super.prepareForReuse()
    prepareViewsForReuse()
    deliveryStatus.text = ""
  }
}
