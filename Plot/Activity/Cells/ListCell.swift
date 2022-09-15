//
//  ListCell.swift
//  Plot
//
//  Created by Cory McHattie on 5/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ListCell: UITableViewCell {
    var iconViewHeightConstraint: NSLayoutConstraint!
    var iconViewTopAnchor: NSLayoutConstraint!
    var iconViewTopAnchorRegular: CGFloat = 8
    let iconViewHeightConstant: CGFloat = 30
    
    var participants: [User] = []
    let thumbnailsCount = 8
    var thumbnails: [UIImageView] = []
    var list: ListType?
    
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
        button.setImage(UIImage(named: "todo"), for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let iconView: UIView = {
        let button = UIView()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let taskNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        label.layer.cornerRadius = 10
        label.text = "1"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        contentView.backgroundColor = .systemGroupedBackground

        contentView.addSubview(activityImageView)
        activityImageView.addSubview(nameLabel)
        activityImageView.addSubview(badgeLabel)
        activityImageView.addSubview(activityTypeButton)
        activityImageView.addSubview(taskNumberLabel)
        activityImageView.addSubview(muteIndicator)
//        activityImageView.addSubview(iconView)
        
        activityImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        activityImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        activityImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        activityImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: activityImageView.bottomAnchor, constant: -10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: activityImageView.leftAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(lessThanOrEqualTo: taskNumberLabel.leftAnchor, constant: -5).isActive = true
        
        activityTypeButton.topAnchor.constraint(equalTo: activityImageView.topAnchor, constant: 10).isActive = true
        activityTypeButton.bottomAnchor.constraint(equalTo: activityImageView.bottomAnchor, constant: -10).isActive = true
        activityTypeButton.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -10).isActive = true
        activityTypeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        activityTypeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        taskNumberLabel.centerYAnchor.constraint(equalTo: activityTypeButton.centerYAnchor, constant: 0).isActive = true
        taskNumberLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
                
        muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 1).isActive = true
        muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 1).isActive = true
        muteIndicator.widthAnchor.constraint(equalToConstant: 15).isActive = true
        muteIndicator.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        badgeLabel.topAnchor.constraint(equalTo: activityTypeButton.bottomAnchor, constant: 10).isActive = true
        badgeLabel.rightAnchor.constraint(equalTo: activityImageView.rightAnchor, constant: -10).isActive = true
        badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 25).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = .systemGroupedBackground
        nameLabel.text = nil
        badgeLabel.isHidden = true
        muteIndicator.isHidden = true
        nameLabel.textColor = .label
        activityTypeButton.setImage(UIImage(named: "todo"), for: .normal)
    }
        
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        activityImageView.backgroundColor = .secondarySystemGroupedBackground.withAlphaComponent(highlighted ? 0.7 : 1)
    }
}

//        var x: CGFloat = 10
//        for _ in 0..<thumbnailsCount {
//            let icon = UIImageView()
//            listImageView.addSubview(icon)
//            thumbnails.append(icon)
//            icon.translatesAutoresizingMaskIntoConstraints = false
//            icon.contentMode = .scaleAspectFill
//            icon.layer.cornerRadius = 15
//            icon.layer.masksToBounds = true
//            icon.image = UIImage(named: "UserpicIcon")
//            icon.topAnchor.constraint(equalTo: activityLabel.bottomAnchor, constant: 8).isActive = true
//            icon.leftAnchor.constraint(equalTo: listImageView.leftAnchor, constant: x).isActive = true
//            icon.widthAnchor.constraint(equalToConstant: 30).isActive = true
//            icon.heightAnchor.constraint(equalToConstant: 30).isActive = true
//            icon.isHidden = true
//            x += 38
//        }


