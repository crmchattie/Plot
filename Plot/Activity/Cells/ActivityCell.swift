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

class ActivityCell: UITableViewCell {
    var invitationSegmentHeightConstraint: NSLayoutConstraint!
    var invitationSegmentedControlTopAnchor: NSLayoutConstraint!
    var invitationSegmentedControlTopAnchorRegular: CGFloat = 8
    let invitationSegmentHeightConstant: CGFloat = 29
    
    var iconViewHeightConstraint: NSLayoutConstraint!
    var iconViewTopAnchor: NSLayoutConstraint!
    var iconViewTopAnchorRegular: CGFloat = 8
    let iconViewHeightConstant: CGFloat = 30
    
    var invitation: Invitation?
    var participants: [User] = []
    let thumbnailsCount = 8
    weak var updateInvitationDelegate: UpdateInvitationDelegate?
    weak var activityViewControllerDataStore: ActivityViewControllerDataStore?
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
        
    let invitationSegmentedControl: UISegmentedControl = {
        let items = ["Accept" , "Decline"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
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
    
    let iconView: UIView = {
        let button = UIView()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        activityImageView.backgroundColor = .tertiarySystemBackground
        contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor

        contentView.addSubview(activityImageView)
        activityImageView.addSubview(nameLabel)
        activityImageView.addSubview(startLabel)
        activityImageView.addSubview(activityTypeLabel)
        activityImageView.addSubview(badgeLabel)
        activityImageView.addSubview(activityTypeButton)
        activityImageView.addSubview(muteIndicator)
//        activityImageView.addSubview(iconView)
        activityImageView.addSubview(invitationSegmentedControl)
        
        activityImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        activityImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        activityImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        activityImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        
        startLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        startLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        startLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
//
        activityTypeLabel.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 2).isActive = true
        activityTypeLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        activityTypeLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        
        activityTypeButton.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        activityTypeButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -10).isActive = true
        activityTypeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        activityTypeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        invitationSegmentedControlTopAnchor = invitationSegmentedControl.topAnchor.constraint(equalTo: activityTypeLabel.bottomAnchor, constant: invitationSegmentedControlTopAnchorRegular)
        invitationSegmentedControlTopAnchor.isActive = true
        invitationSegmentedControl.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 5).isActive = true
        invitationSegmentedControl.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -5).isActive = true
        invitationSegmentedControl.bottomAnchor.constraint(equalTo: activityImageView.bottomAnchor, constant: -10).isActive = true
        invitationSegmentHeightConstraint = invitationSegmentedControl.heightAnchor.constraint(equalToConstant: invitationSegmentHeightConstant)
        invitationSegmentHeightConstraint.isActive = true
        
        muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 1).isActive = true
        muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 1).isActive = true
        muteIndicator.widthAnchor.constraint(equalToConstant: 15).isActive = true
        muteIndicator.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        badgeLabel.topAnchor.constraint(equalTo: activityTypeButton.bottomAnchor, constant: 10).isActive = true
        badgeLabel.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -10).isActive = true
        badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 25).isActive = true
        
        invitationSegmentedControl.addTarget(self, action: #selector(ActivityCell.indexChangedSegmentedControl(_:)), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        nameLabel.text = nil
        startLabel.text = nil
        activityTypeLabel.text = nil
        badgeLabel.isHidden = true
        muteIndicator.isHidden = true
        nameLabel.textColor = .label
        activityTypeButton.setImage(UIImage(named: "activity"), for: .normal)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        activityImageView.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(highlighted ? 0.7 : 1)
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
}
