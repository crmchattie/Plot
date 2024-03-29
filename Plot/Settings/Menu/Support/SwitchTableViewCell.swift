//
//  SwitchTableViewCell.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/17/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


class SwitchTableViewCell: UITableViewCell {
    
    weak var currentViewController: UIViewController?
    
    static let viewsXPos: CGFloat = 15
    
    var title: UILabel = {
        var title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = UIFont.preferredFont(forTextStyle: .body)
        title.adjustsFontForContentSizeCategory = true
        title.textColor = .label
        return title
    }()
    
    var switchAccessory: UISwitch = {
        var switchAccessory = UISwitch()
        switchAccessory.translatesAutoresizingMaskIntoConstraints = false
        switchAccessory.isEnabled = true
        switchAccessory.isUserInteractionEnabled = true
        return switchAccessory
    }()
    
    var switchTapAction: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .secondarySystemGroupedBackground
        selectionStyle = .none
        
        addSubview(switchAccessory)
        addSubview(title)
        
        switchAccessory.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        switchAccessory.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        if #available(iOS 11.0, *) {
            switchAccessory.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        } else {
            switchAccessory.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
        }
        
        title.centerYAnchor.constraint(equalTo: switchAccessory.centerYAnchor).isActive = true
        title.rightAnchor.constraint(equalTo: switchAccessory.leftAnchor, constant: -5).isActive = true
        
        if #available(iOS 11.0, *) {
            title.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: SwitchTableViewCell.viewsXPos).isActive = true
        } else {
            title.leftAnchor.constraint(equalTo: leftAnchor, constant: SwitchTableViewCell.viewsXPos).isActive = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell(object: SwitchObject, index: Int) {
        title.text = object.title
        switchAccessory.isOn = object.state
        
        switchTapAction = { (isOn) in
            if let notificationsTableViewController = self.currentViewController as? NotificationsTableViewController {
                notificationsTableViewController.notificationElements[index].state = isOn
            } else if let privacyTableViewController = self.currentViewController as? PrivacyTableViewController {
                privacyTableViewController.privacyElements[index].state = isOn
            }
        }
    }
}

