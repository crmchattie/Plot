//
//  UserCell.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

protocol ChatCellDelegate: class {
    func getInfo(forConversation conversation: Conversation)
    func openActivity(forConversation conversation: Conversation)
}

class UserCell: BaseContainerTableViewCell {
    
    let thumbnailsCount = 9
    var thumbnails: [UIImageView] = []
    weak var chatsViewControllerDataStore: ChatsViewControllerDataStore?
    var conversation: Conversation?
    weak var delegate: ChatCellDelegate?
    
    let chatImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    //blue dot on the left of cell
    let newMessageIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        imageView.image = UIImage(named: "Oval")
        
        return imageView
    }()
    
    let muteIndicator: UIImageView = {
        let muteIndicator = UIImageView()
        muteIndicator.translatesAutoresizingMaskIntoConstraints = false
        muteIndicator.layer.masksToBounds = true
        muteIndicator.contentMode = .scaleAspectFit
        muteIndicator.isHidden = true
        muteIndicator.image = UIImage(named: "mute")
        
        return muteIndicator
    }()
    
    //channel time of last sent text in specific chat
    let timeLabel: UILabel = {
        let label = UILabel()
        //      label.font = UIFont.systemFont(ofSize: 12)
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.minimumScaleFactor = 0.1
        label.adjustsFontSizeToFitWidth = true
        
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        label.textAlignment = .left
        
        return label
    }()
    
    //channel view name of specific chat
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        //      label.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.semibold)
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.minimumScaleFactor = 0.1
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }()
    
    //channel view last text in specific chat
    let messageLabel: UILabel = {
        let label = UILabel()
        //      label.font = UIFont.systemFont(ofSize: 13)
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }()
    
    let badgeLabel: UILabel = {
        let badgeLabel = UILabel()
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.backgroundColor = FalconPalette.defaultBlue
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.text = "1"
        badgeLabel.isHidden = true
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.layer.masksToBounds = true
        badgeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        badgeLabel.adjustsFontForContentSizeCategory = true
        badgeLabel.minimumScaleFactor = 0.1
        badgeLabel.adjustsFontSizeToFitWidth = true
        
        return badgeLabel
    }()
    
    let chatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "chat"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        return button
    }()
    
    let activityButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "activity"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let infoButton: UIButton = {
        let button = UIButton(type: .infoLight)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        chatImageView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        
        contentView.addSubview(chatImageView)
        chatImageView.addSubview(nameLabel)
        chatImageView.addSubview(messageLabel)
        chatImageView.addSubview(timeLabel)
        chatImageView.addSubview(muteIndicator)
        chatImageView.addSubview(badgeLabel)
        chatImageView.addSubview(newMessageIndicator)
        chatImageView.addSubview(chatButton)
        chatImageView.addSubview(activityButton)
        chatImageView.addSubview(infoButton)
        
        chatImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        chatImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        chatImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0).isActive = true
        chatImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: chatImageView.topAnchor, constant: 10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: chatImageView.leftAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: chatButton.leftAnchor, constant: -20).isActive = true
        
        messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: chatImageView.leftAnchor, constant: 10).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: chatButton.leftAnchor, constant: -5).isActive = true
        
        timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 2).isActive = true
        timeLabel.leftAnchor.constraint(equalTo: chatImageView.leftAnchor, constant: 10).isActive = true
        timeLabel.rightAnchor.constraint(equalTo: chatButton.leftAnchor, constant: -15).isActive = true
    
        muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 3).isActive = true
        muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 1).isActive = true
        muteIndicator.widthAnchor.constraint(equalToConstant: 12).isActive = true
        muteIndicator.heightAnchor.constraint(equalToConstant: 12).isActive = true
        
        newMessageIndicator.rightAnchor.constraint(equalTo: chatImageView.leftAnchor, constant: 11).isActive = true
        newMessageIndicator.centerYAnchor.constraint(equalTo: chatImageView.centerYAnchor).isActive = true
        newMessageIndicator.widthAnchor.constraint(equalToConstant: 10).isActive = true
        newMessageIndicator.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        badgeLabel.centerYAnchor.constraint(equalTo: activityButton.centerYAnchor).isActive = true
        badgeLabel.rightAnchor.constraint(equalTo: activityButton.leftAnchor, constant: -10).isActive = true
        badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 25).isActive = true
        
        chatButton.topAnchor.constraint(equalTo: chatImageView.topAnchor, constant: 10).isActive = true
        chatButton.rightAnchor.constraint(equalTo: chatImageView.rightAnchor, constant: -10).isActive = true
        chatButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        chatButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        activityButton.topAnchor.constraint(equalTo: chatButton.bottomAnchor, constant: 8).isActive = true
        activityButton.rightAnchor.constraint(equalTo: chatImageView.rightAnchor, constant: -10).isActive = true
        activityButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        activityButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        activityButton.addTarget(self, action: #selector(UserCell.activityButtonTapped), for: .touchUpInside)
        
        infoButton.topAnchor.constraint(equalTo: activityButton.bottomAnchor, constant: 8).isActive = true
        infoButton.bottomAnchor.constraint(equalTo: chatImageView.bottomAnchor, constant: -10).isActive = true
        infoButton.rightAnchor.constraint(equalTo: chatImageView.rightAnchor, constant: -10).isActive = true
        infoButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        infoButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        infoButton.addTarget(self, action: #selector(UserCell.getInfoAction), for: .touchUpInside)
        
        var x: CGFloat = 10
        for _ in 0..<thumbnailsCount {
            let icon = UIImageView()
            chatImageView.addSubview(icon)
            thumbnails.append(icon)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFill
            icon.layer.cornerRadius = 15
            icon.layer.masksToBounds = true
            icon.image = UIImage(named: "UserpicIcon")
            icon.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8).isActive = true
            icon.leftAnchor.constraint(equalTo: chatImageView.leftAnchor, constant: x).isActive = true
            icon.widthAnchor.constraint(equalToConstant: 30).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 30).isActive = true
            icon.isHidden = true
            x += 38
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        chatImageView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        nameLabel.text = ""
        messageLabel.text = nil
        timeLabel.text = nil
        badgeLabel.isHidden = true
        muteIndicator.isHidden = true
        newMessageIndicator.isHidden = true
        nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    }
    
    @objc func getInfoAction() {
        guard let conversation = conversation else {
            return
        }
        
        
        self.delegate?.getInfo(forConversation: conversation)
    }
    
    @objc func activityButtonTapped() {
        guard let conversation = conversation else {
            return
        }
        
        
        self.delegate?.openActivity(forConversation: conversation)
    }
}
