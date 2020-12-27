//
//  ActivityCell.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

protocol ActivityCellDelegate: class {
    func openMap(forActivity activity: Activity)
    func openChat(forConversation conversationID: String?, activityID: String?)
}

class ActivityCell: UITableViewCell {
    
    var invitationSegmentHeightConstraint: NSLayoutConstraint!
    var invitationSegmentedControlTopAnchor: NSLayoutConstraint!
    let invitationSegmentedControlTopAnchorShowAvatar: CGFloat = 35
    let invitationSegmentedControlTopAnchorRegular: CGFloat = 17
    let invitationSegmentHeightConstant: CGFloat = 29
    var invitation: Invitation?
    var participants: [User] = []
    let thumbnailsCount = 9
    weak var updateInvitationDelegate: UpdateInvitationDelegate?
    weak var activityViewControllerDataStore: ActivityViewControllerDataStore?
    weak var delegate: ActivityCellDelegate?
    var thumbnails: [UIImageView] = []
    var activity: Activity?
    
    //name of activity
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    let activityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    //blue dot on the left of cell
    let newActivityIndicator: UIImageView = {
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
    
    //date/time of activity
    let startLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        label.textAlignment = .left
        return label
    }()
    
    //activity type label (e.g. drinks, trip)
    let activityTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    //activity participants label (e.g. whoever is invited to activity)
    let activityParticipantsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    //activity address label (e.g. address of restaurant, initial lodgings with trip)
    let activityAddressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let invitationSegmentedControl: UISegmentedControl = {
        let items = ["Accept" , "Decline"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
        } else {
            // Fallback on earlier versions
        }
        
        return segmentedControl
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
    
    let activityTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "activity"), for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let chatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "chat"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let mapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "map"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "list"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
                
        contentView.addSubview(activityImageView)
        activityImageView.addSubview(nameLabel)
        activityImageView.addSubview(startLabel)
        activityImageView.addSubview(activityTypeLabel)
        activityImageView.addSubview(activityAddressLabel)
        activityImageView.addSubview(muteIndicator)
        activityImageView.addSubview(newActivityIndicator)
        activityImageView.addSubview(invitationSegmentedControl)
        activityImageView.addSubview(badgeLabel)
        activityImageView.addSubview(activityTypeButton)
        activityImageView.addSubview(chatButton)
        activityImageView.addSubview(listButton)
        activityImageView.addSubview(mapButton)
        
        activityImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        activityImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true
        activityImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 5).isActive = true
        activityImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 5).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        
        startLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        startLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 5).isActive = true
        startLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        
        activityTypeLabel.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 2).isActive = true
        activityTypeLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 5).isActive = true
        activityTypeLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        
        activityAddressLabel.topAnchor.constraint(equalTo: activityTypeLabel.bottomAnchor, constant: 2).isActive = true
        activityAddressLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 5).isActive = true
        activityAddressLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        
        activityTypeButton.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 5).isActive = true
        activityTypeButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        activityTypeButton.widthAnchor.constraint(equalToConstant: 29).isActive = true
        activityTypeButton.heightAnchor.constraint(equalToConstant: 29).isActive = true
        
        chatButton.topAnchor.constraint(equalTo: activityTypeButton.bottomAnchor, constant: 5).isActive = true
        chatButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        chatButton.widthAnchor.constraint(equalToConstant: 29).isActive = true
        chatButton.heightAnchor.constraint(equalToConstant: 29).isActive = true
        
        listButton.topAnchor.constraint(equalTo: chatButton.bottomAnchor, constant: 5).isActive = true
        listButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -2).isActive = true
        listButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        listButton.heightAnchor.constraint(equalToConstant: 29).isActive = true
        
        mapButton.topAnchor.constraint(equalTo: listButton.bottomAnchor, constant: 5).isActive = true
        mapButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        mapButton.widthAnchor.constraint(equalToConstant: 29).isActive = true
        mapButton.heightAnchor.constraint(equalToConstant: 29).isActive = true

        var x: CGFloat = 5
        for _ in 0..<thumbnailsCount {
            let icon = UIImageView()
            activityImageView.addSubview(icon)
            thumbnails.append(icon)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFill
            icon.layer.cornerRadius = 15
            icon.layer.masksToBounds = true
            icon.image = UIImage(named: "UserpicIcon")
            icon.topAnchor.constraint(equalTo: activityAddressLabel.bottomAnchor, constant: 8).isActive = true
//            icon.bottomAnchor.constraint(lessThanOrEqualTo: invitationSegmentedControl.topAnchor, constant: -5).isActive = true
            icon.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: x).isActive = true
            icon.widthAnchor.constraint(equalToConstant: 30).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 30).isActive = true
            icon.isHidden = true
            x += 38
        }
        
        
        invitationSegmentedControlTopAnchor = invitationSegmentedControl.topAnchor.constraint(equalTo: mapButton.bottomAnchor, constant: invitationSegmentedControlTopAnchorRegular)
        invitationSegmentedControlTopAnchor.isActive = true
        invitationSegmentedControl.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 5).isActive = true
        invitationSegmentedControl.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        invitationSegmentedControl.bottomAnchor.constraint(equalTo: activityImageView.bottomAnchor, constant: -5).isActive = true
        invitationSegmentHeightConstraint = invitationSegmentedControl.heightAnchor.constraint(equalToConstant: invitationSegmentHeightConstant)
        invitationSegmentHeightConstraint.isActive = true
        
        muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 1).isActive = true
        muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 1).isActive = true
        muteIndicator.widthAnchor.constraint(equalToConstant: 15).isActive = true
        muteIndicator.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        newActivityIndicator.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 5).isActive = true
        newActivityIndicator.centerYAnchor.constraint(equalTo: activityImageView.centerYAnchor).isActive = true
        newActivityIndicator.widthAnchor.constraint(equalToConstant: 10).isActive = true
        newActivityIndicator.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        badgeLabel.topAnchor.constraint(equalTo: chatButton.topAnchor, constant: 25).isActive = true
        badgeLabel.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -50).isActive = true
        badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 25).isActive = true
        
        invitationSegmentedControl.addTarget(self, action: #selector(ActivityCell.indexChangedSegmentedControl(_:)), for: .valueChanged)
        mapButton.addTarget(self, action: #selector(ActivityCell.mapButtonTapped), for: .touchUpInside)
        chatButton.addTarget(self, action: #selector(ActivityCell.chatButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        activityImageView.image = nil
        activityImageView.sd_cancelCurrentImageLoad()
        nameLabel.text = nil
        startLabel.text = nil
        activityTypeLabel.text = nil
        activityAddressLabel.text = nil
        badgeLabel.isHidden = true
        muteIndicator.isHidden = true
        newActivityIndicator.isHidden = true
        nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        activityTypeButton.setImage(UIImage(named: "activity"), for: .normal)
    }
    
    @objc func indexChangedSegmentedControl(_ sender: UISegmentedControl) {
        guard let invitation = self.invitation else {
            return
        }
        
        var updatedInvitation = invitation
        switch sender.selectedSegmentIndex{
        case 0:
            updatedInvitation.status = .accepted
        case 1:
            updatedInvitation.status = .declined
        default:
            break
        }
        
        self.updateInvitationDelegate?.updateInvitation(invitation: updatedInvitation)
    }
    
    @objc func mapButtonTapped() {
        guard let activity = activity else {
            return
        }
        self.delegate?.openMap(forActivity: activity)
    }
    
    
    @objc func chatButtonTapped() {
        if let activity = activity, let conversationID = activity.conversationID {
            self.delegate?.openChat(forConversation: conversationID, activityID: activity.activityID)
        } else if let activity = activity {
            self.delegate?.openChat(forConversation: nil, activityID: activity.activityID)
        }
    }
}
