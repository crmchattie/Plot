//
//  ActivityView.swift
//  Plot
//
//  Created by Cory McHattie on 8/23/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

let kCalendarScope = "CalendarScope"

class ActivityView: UIView {
    
    let calendar = FSCalendar()
    var calendarHeightConstraint: NSLayoutConstraint?

    let tableView: UITableViewWithReloadCompletion = {
        let tableView = UITableViewWithReloadCompletion()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    let arrowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "up-arrow"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = ThemeManager.currentTheme().generalTitleColor
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)        
        calendar.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(calendar)
        calendar.addSubview(arrowButton)
        addSubview(tableView)
    
        calendar.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: topAnchor, constant: -5),
            calendar.leftAnchor.constraint(equalTo: leftAnchor),
            calendar.rightAnchor.constraint(equalTo: rightAnchor),
//            calendar.bottomAnchor.constraint(equalTo: arrowButton.topAnchor, constant: 10),
            
            arrowButton.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: -12),
            arrowButton.widthAnchor.constraint(equalToConstant: 15),
            arrowButton.heightAnchor.constraint(equalToConstant: 15),
            arrowButton.centerXAnchor.constraint(equalTo: calendar.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 0),
            tableView.leftAnchor.constraint(equalTo: leftAnchor),
            tableView.rightAnchor.constraint(equalTo: rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        self.calendarHeightConstraint = NSLayoutConstraint(item: calendar, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 300)
        self.addConstraint(calendarHeightConstraint!)
        print("calendarHeightConstraint \(calendarHeightConstraint?.constant)")
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func updateArrowDirection(down: Bool) {
        let name = down ? "down-arrow" : "up-arrow"
        arrowButton.setImage(UIImage(named: name), for: .normal)
    }
}
