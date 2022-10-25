//
//  EventCell.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class EventCell: UITableViewCell {
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
    var thumbnails: [UIImageView] = []
    var activity: Activity?
    
    //name of activity
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
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
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        return label
    }()
    
    //activity type label (e.g. drinks, trip)
    let activityTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    //activity participants label (e.g. whoever is invited to activity)
    let activityParticipantsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
        
    let invitationSegmentedControl: UISegmentedControl = {
        let items = ["Accept" , "Decline"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
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
        return badgeLabel
    }()
    
    let activityTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "event"), for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .systemBlue
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
        contentView.backgroundColor = .systemGroupedBackground

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
        nameLabel.rightAnchor.constraint(equalTo: badgeLabel.leftAnchor, constant: -5).isActive = true
        
        startLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        startLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        startLabel.rightAnchor.constraint(equalTo: badgeLabel.leftAnchor, constant: -5).isActive = true
//
        activityTypeLabel.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 2).isActive = true
        activityTypeLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        activityTypeLabel.rightAnchor.constraint(equalTo: badgeLabel.leftAnchor, constant: -5).isActive = true
        
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
        
        muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 5).isActive = true
        muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        muteIndicator.widthAnchor.constraint(equalToConstant: 15).isActive = true
        muteIndicator.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        badgeLabel.centerYAnchor.constraint(equalTo: activityTypeButton.centerYAnchor).isActive = true
        badgeLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        badgeLabel.widthAnchor.constraint(equalToConstant: 25).isActive = true
        badgeLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        invitationSegmentedControl.addTarget(self, action: #selector(EventCell.indexChangedSegmentedControl(_:)), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = .systemGroupedBackground
        nameLabel.text = nil
        startLabel.text = nil
        activityTypeLabel.text = nil
        badgeLabel.isHidden = true
        muteIndicator.isHidden = true
        nameLabel.textColor = .label
        activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
        activityTypeButton.tintColor = .systemBlue
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        activityImageView.backgroundColor = .secondarySystemGroupedBackground.withAlphaComponent(highlighted ? 0.7 : 1)
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

class EventCollectionCell: UICollectionViewCell {
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
    var thumbnails: [UIImageView] = []
    var activity: Activity?
    
    //name of activity
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
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
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        return label
    }()
    
    //activity type label (e.g. drinks, trip)
    let activityTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    //activity participants label (e.g. whoever is invited to activity)
    let activityParticipantsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
        
    let invitationSegmentedControl: UISegmentedControl = {
        let items = ["Accept" , "Decline"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
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
        return badgeLabel
    }()
    
    let activityTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "event"), for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .systemBlue
        return button
    }()
    
    let iconView: UIView = {
        let button = UIView()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var widthConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGroupedBackground
        activityImageView.backgroundColor = .secondarySystemGroupedBackground
        
        widthConstraint = widthAnchor.constraint(equalToConstant: -30)
                
        addSubview(activityImageView)
        activityImageView.addSubview(nameLabel)
        activityImageView.addSubview(startLabel)
        activityImageView.addSubview(activityTypeLabel)
        activityImageView.addSubview(badgeLabel)
        activityImageView.addSubview(activityTypeButton)
        activityImageView.addSubview(muteIndicator)
//        activityImageView.addSubview(iconView)
        activityImageView.addSubview(invitationSegmentedControl)
        
        activityImageView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        activityImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        activityImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        activityImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: badgeLabel.leftAnchor, constant: -5).isActive = true
        
        startLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        startLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        startLabel.rightAnchor.constraint(equalTo: badgeLabel.leftAnchor, constant: -5).isActive = true
//
        activityTypeLabel.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 2).isActive = true
        activityTypeLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        activityTypeLabel.rightAnchor.constraint(equalTo: badgeLabel.leftAnchor, constant: -5).isActive = true
        
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
        
        muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 5).isActive = true
        muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        muteIndicator.widthAnchor.constraint(equalToConstant: 15).isActive = true
        muteIndicator.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        badgeLabel.centerYAnchor.constraint(equalTo: activityTypeButton.centerYAnchor).isActive = true
        badgeLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        badgeLabel.widthAnchor.constraint(equalToConstant: 25).isActive = true
        badgeLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        invitationSegmentedControl.addTarget(self, action: #selector(EventCell.indexChangedSegmentedControl(_:)), for: .valueChanged)
    }
    
    override func updateConstraints() {
        // Set width constraint to superview's width.
        widthConstraint?.constant = (superview?.bounds.width ?? 0) - 30
        widthConstraint?.isActive = true
        super.updateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundColor = .systemGroupedBackground
        activityImageView.backgroundColor = .secondarySystemGroupedBackground
        nameLabel.text = nil
        startLabel.text = nil
        activityTypeLabel.text = nil
        badgeLabel.isHidden = true
        muteIndicator.isHidden = true
        nameLabel.textColor = .label
        activityTypeButton.setImage(UIImage(named: "event"), for: .normal)
        activityTypeButton.tintColor = .systemBlue
    }
    
    override var isHighlighted: Bool {
        didSet {
            activityImageView.backgroundColor = .secondarySystemGroupedBackground.withAlphaComponent(isHighlighted ? 0.7 : 1)
        }
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
