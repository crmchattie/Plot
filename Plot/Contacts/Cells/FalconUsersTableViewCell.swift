//
//  FalconUsersTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage

class FalconUsersTableViewCell: UITableViewCell {
    
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
        title.textColor = .label
        title.adjustsFontForContentSizeCategory = true
        return title
    }()
    
    var subtitle: UILabel = {
        var subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .secondaryLabel
        subtitle.adjustsFontForContentSizeCategory = true
        return subtitle
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 65).isActive = true
        
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
        
        contentView.addSubview(subtitle)
        subtitle.bottomAnchor.constraint(equalTo: icon.bottomAnchor, constant: 0).isActive = true
        subtitle.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 15).isActive = true
        subtitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        subtitle.heightAnchor.constraint(equalToConstant: 23).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        icon.image = UIImage(named: "UserpicIcon")
        icon.sd_cancelCurrentImageLoad()
        title.text = ""
        subtitle.text = ""
        title.textColor = .label
        subtitle.textColor = .secondaryLabel
    }
    
    func configureCell(for user: User) {
        title.text = user.name ?? ""
        
        if let statusString = user.onlineStatus as? String {
            if statusString == statusOnline {
                subtitle.textColor = FalconPalette.defaultBlue
                subtitle.text = statusString
            }
        }
        
        if let lastSeen = user.onlineStatus as? TimeInterval {
            let date = Date(timeIntervalSince1970: lastSeen/1000)
            let lastSeenTime = "Last seen " + timeAgoSinceDate(date)
            subtitle.textColor = .secondaryLabel
            subtitle.text = lastSeenTime
        }
        
        guard let urlString = user.thumbnailPhotoURL else { return }
        let options: SDWebImageOptions = [.scaleDownLargeImages, .continueInBackground, .avoidAutoSetImage]
        let placeholder = UIImage(named: "UserpicIcon")
        icon.sd_setImage(with: URL(string: urlString), placeholderImage: placeholder, options: options) { (image, _, cacheType, _) in
            guard image != nil else { return }
            guard cacheType != .memory, cacheType != .disk else {
                self.icon.image = image
                return
            }
            UIView.transition(with: self.icon, duration: 0.2, options: .transitionCrossDissolve, animations: { self.icon.image = image }, completion: nil)
        }
    }
}
