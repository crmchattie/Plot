//
//  ParticipantTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/9/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class ParticipantTableViewCell: UITableViewCell {
    
    weak var selectParticipantsViewController: SelectParticipantsViewController!
    
    var gestureReconizer:UITapGestureRecognizer!
    var allowSelection = true
    
    var icon: UIImageView = {
        var icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFill
        icon.layer.cornerRadius = 22
        icon.layer.masksToBounds = true
        icon.image = UIImage(named: "UserpicIcon")
        
        return icon
    }()
    
    var title: UILabel = {
        var title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = UIFont.preferredFont(forTextStyle: .headline)
        title.adjustsFontForContentSizeCategory = true
        title.textColor = .label
        return title
    }()
    
    var subtitle: UILabel = {
        var subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.textColor = .secondaryLabel
        
        return subtitle
    }()
    
    var rightSubtitle: UILabel = {
        var subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.textAlignment = .right
        subtitle.textColor = .secondaryLabel
        return subtitle
    }()    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 65).isActive = true
        
        gestureReconizer = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(gestureReconizer)
        
        backgroundColor = .clear
        title.backgroundColor = backgroundColor
        icon.backgroundColor = backgroundColor
        
        contentView.addSubview(icon)
        icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
        icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 46).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 46).isActive = true
        
        contentView.addSubview(title)
        title.topAnchor.constraint(equalTo: icon.topAnchor, constant: 0).isActive = true
        title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 15).isActive = true
        title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        title.heightAnchor.constraint(equalToConstant: 23).isActive = true
        
        contentView.addSubview(rightSubtitle)
        contentView.addSubview(subtitle)
        
        subtitle.bottomAnchor.constraint(equalTo: icon.bottomAnchor, constant: 0).isActive = true
        subtitle.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 15).isActive = true

        subtitle.heightAnchor.constraint(equalToConstant: 23).isActive = true
        
        rightSubtitle.bottomAnchor.constraint(equalTo: icon.bottomAnchor, constant: 0).isActive = true
        rightSubtitle.leadingAnchor.constraint(equalTo: subtitle.trailingAnchor, constant: 10).isActive = true
        rightSubtitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        rightSubtitle.heightAnchor.constraint(equalToConstant: 23).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func cellTapped() {
        guard allowSelection, let indexPath = selectParticipantsViewController.tableView.indexPathForView(self) else { return }
        if isSelected {
            selectParticipantsViewController.didDeselectUser(at: indexPath)
            isSelected = false
        } else {
            selectParticipantsViewController.didSelectUser(at: indexPath)
            isSelected = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        icon.image = UIImage(named: "UserpicIcon")
        title.text = ""
        subtitle.text = ""
        title.textColor = .label
        subtitle.textColor = .secondaryLabel
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
