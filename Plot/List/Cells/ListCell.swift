//
//  ListCell.swift
//  Plot
//
//  Created by Cory McHattie on 5/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol ListCellDelegate: AnyObject {
    func openActivity(activityID: String)
    func openChat(forConversation conversationID: String?, grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?, activitylist: Activitylist?)
}

class ListCell: UITableViewCell {
    let thumbnailsCount = 9
    var thumbnails: [UIImageView] = []
    
    weak var activityViewControllerDataStore: ActivityViewControllerDataStore?
    weak var listViewControllerDataStore: ListViewControllerDataStore?
    
    var grocerylist: Grocerylist?
    var checklist: Checklist?
    var packinglist: Packinglist?
    var activitylist: Activitylist?
    
    weak var delegate: ListCellDelegate?
    
    let listImageView: UIImageView = {
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
    
    //channel view name of specific chat
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    //channel view last text in specific chat
    let listTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    let activityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
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
    
    let listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "list"), for: .normal)
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
    
    let chatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "chat"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        contentView.addSubview(listImageView)
        listImageView.addSubview(nameLabel)
        listImageView.addSubview(listTypeLabel)
        listImageView.addSubview(timeLabel)
        listImageView.addSubview(activityLabel)
        listImageView.addSubview(muteIndicator)
        listImageView.addSubview(badgeLabel)
        listImageView.addSubview(newMessageIndicator)
        listImageView.addSubview(listButton)
        listImageView.addSubview(activityButton)
        listImageView.addSubview(chatButton)
        
        listImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        listImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true
        listImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        listImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
        
        newMessageIndicator.rightAnchor.constraint(equalTo: listImageView.leftAnchor, constant: 11).isActive = true
        newMessageIndicator.centerYAnchor.constraint(equalTo: activityButton.centerYAnchor).isActive = true
        newMessageIndicator.widthAnchor.constraint(equalToConstant: 10).isActive = true
        newMessageIndicator.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: listImageView.topAnchor, constant: 10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: listImageView.leftAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: listButton.leftAnchor, constant: -20).isActive = true
        
        listTypeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        listTypeLabel.leftAnchor.constraint(equalTo: listImageView.leftAnchor, constant: 10).isActive = true
        listTypeLabel.rightAnchor.constraint(equalTo: listButton.leftAnchor, constant: -5).isActive = true
        
        timeLabel.topAnchor.constraint(equalTo: listTypeLabel.bottomAnchor, constant: 2).isActive = true
        timeLabel.leftAnchor.constraint(equalTo: listImageView.leftAnchor, constant: 10).isActive = true
        timeLabel.rightAnchor.constraint(equalTo: listButton.leftAnchor, constant: -5).isActive = true
        
        activityLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2).isActive = true
        activityLabel.leftAnchor.constraint(equalTo: listImageView.leftAnchor, constant: 10).isActive = true
        activityLabel.rightAnchor.constraint(equalTo: listButton.leftAnchor, constant: -5).isActive = true
        
        muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 3).isActive = true
        muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 1).isActive = true
        muteIndicator.widthAnchor.constraint(equalToConstant: 12).isActive = true
        muteIndicator.heightAnchor.constraint(equalToConstant: 12).isActive = true
        
        badgeLabel.rightAnchor.constraint(equalTo: listImageView.rightAnchor, constant: -50).isActive = true
        badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 25).isActive = true
        badgeLabel.centerYAnchor.constraint(equalTo: activityButton.centerYAnchor).isActive = true
        badgeLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
                
        listButton.topAnchor.constraint(equalTo: listImageView.topAnchor, constant: 2).isActive = true
        listButton.rightAnchor.constraint(equalTo: listImageView.rightAnchor, constant: -2).isActive = true
        listButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
        listButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        activityButton.topAnchor.constraint(equalTo: listButton.bottomAnchor, constant: 10).isActive = true
        activityButton.rightAnchor.constraint(equalTo: listImageView.rightAnchor, constant: -5).isActive = true
        activityButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        activityButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        activityButton.addTarget(self, action: #selector(ListCell.activityButtonTapped), for: .touchUpInside)
        
        chatButton.topAnchor.constraint(equalTo: activityButton.bottomAnchor, constant: 10).isActive = true
        chatButton.bottomAnchor.constraint(equalTo: listImageView.bottomAnchor, constant: -12).isActive = true
        chatButton.rightAnchor.constraint(equalTo: listImageView.rightAnchor, constant: -5).isActive = true
        chatButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        chatButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        chatButton.addTarget(self, action: #selector(ListCell.chatButtonTapped), for: .touchUpInside)
        
        var x: CGFloat = 10
        for _ in 0..<thumbnailsCount {
            let icon = UIImageView()
            listImageView.addSubview(icon)
            thumbnails.append(icon)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFill
            icon.layer.cornerRadius = 15
            icon.layer.masksToBounds = true
            icon.image = UIImage(named: "UserpicIcon")
            icon.topAnchor.constraint(equalTo: activityLabel.bottomAnchor, constant: 8).isActive = true
            icon.leftAnchor.constraint(equalTo: listImageView.leftAnchor, constant: x).isActive = true
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
        grocerylist = nil
        checklist = nil
        packinglist = nil
        activitylist = nil
        nameLabel.text = ""
        listTypeLabel.text = nil
        activityLabel.text = nil
        timeLabel.text = nil
        badgeLabel.isHidden = true
        muteIndicator.isHidden = true
        newMessageIndicator.isHidden = true
        nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    }
    
    @objc func activityButtonTapped() {
        if let grocerylist = grocerylist, let activityID = grocerylist.activityID {
            self.delegate?.openActivity(activityID: activityID)
        } else if let checklist = checklist, let activityID = checklist.activityID {
            self.delegate?.openActivity(activityID: activityID)
        } else if let activitylist = activitylist, let activityID = activitylist.activityID {
            self.delegate?.openActivity(activityID: activityID)
        } else if let packinglist = packinglist, let activityID = packinglist.activityID {
            self.delegate?.openActivity(activityID: activityID)
        }
    }
    
    @objc func chatButtonTapped() {
        if let grocerylist = grocerylist {
            if let conversationID = grocerylist.conversationID {
                self.delegate?.openChat(forConversation: conversationID, grocerylist: grocerylist, checklist: nil, packinglist: nil, activitylist: nil)
            } else {
                self.delegate?.openChat(forConversation: nil, grocerylist: grocerylist, checklist: nil, packinglist: nil, activitylist: nil)
            }
        } else if let checklist = checklist {
            if let conversationID = checklist.conversationID {
                self.delegate?.openChat(forConversation: conversationID, grocerylist: nil, checklist: checklist, packinglist: nil, activitylist: nil)
            } else {
                self.delegate?.openChat(forConversation: nil, grocerylist: nil, checklist: checklist, packinglist: nil, activitylist: nil)
            }
        } else if let activitylist = activitylist {
            if let conversationID = activitylist.conversationID {
                self.delegate?.openChat(forConversation: conversationID, grocerylist: nil, checklist: nil, packinglist: nil, activitylist: activitylist)
            } else {
                self.delegate?.openChat(forConversation: nil, grocerylist: nil, checklist: nil, packinglist: nil, activitylist: activitylist)
            }
        } else if let packinglist = packinglist {
            if let conversationID = packinglist.conversationID {
                self.delegate?.openChat(forConversation: conversationID, grocerylist: nil, checklist: nil, packinglist: packinglist, activitylist: nil)
            } else {
                self.delegate?.openChat(forConversation: nil, grocerylist: nil, checklist: nil, packinglist: packinglist, activitylist: nil)
            }
        }
    }
}


