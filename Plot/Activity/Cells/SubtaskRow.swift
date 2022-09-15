//
//  SubtaskRow.swift
//  Plot
//
//  Created by Cory McHattie on 8/20/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Eureka

protocol UpdateTaskCellDelegate: AnyObject {
    func updateCompletion(task: Activity)
}

final class SubtaskCell: Cell<Activity>, CellType {
    weak var delegate: UpdateTaskCellDelegate?
        
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    //activity type label (e.g. drinks, trip)
    lazy var locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    lazy var dateTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        
        return label
    }()

    //blue dot on the left of cell
    let activityTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "activity"), for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let checkView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let checkImage: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let checkConfiguration = UIImage.SymbolConfiguration(weight: .medium)
    
    override func setup() {
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        textLabel?.textColor = .clear
        
        backgroundColor = .secondarySystemGroupedBackground
        contentView.addSubview(nameLabel)
        contentView.addSubview(dateTimeLabel)
        contentView.addSubview(locationNameLabel)
        contentView.addSubview(checkView)
        checkView.addSubview(checkImage)
        
        nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(lessThanOrEqualTo: checkView.rightAnchor, constant: -15).isActive = true
        
        dateTimeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        dateTimeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        dateTimeLabel.rightAnchor.constraint(lessThanOrEqualTo: checkView.rightAnchor, constant: -15).isActive = true
                        
        locationNameLabel.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 2).isActive = true
        locationNameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        locationNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        locationNameLabel.rightAnchor.constraint(lessThanOrEqualTo: checkView.rightAnchor, constant: -15).isActive = true
        
        checkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        checkView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0).isActive = true
        checkView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0).isActive = true
        checkView.widthAnchor.constraint(equalToConstant: 40).isActive = true

        checkImage.centerYAnchor.constraint(equalTo: checkView.centerYAnchor, constant: 0).isActive = true
        checkImage.leftAnchor.constraint(equalTo: checkView.leftAnchor, constant: -10).isActive = true
        checkImage.widthAnchor.constraint(equalToConstant: 30).isActive = true
        checkImage.heightAnchor.constraint(equalToConstant: 30).isActive = true
                        
    }
    
    override func update() {
        height = { 60 }
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil

        guard let subtask = row.value else { return }
                
        nameLabel.text = subtask.name

        if let _ = subtask.endDate {
            let dateTimeValue = dateTimeValue(forTask: subtask)
            dateTimeLabel.text = dateTimeValue
        } else {
            dateTimeLabel.text = ""
        }
        
        // set the texts to the labels
        if subtask.locationName != "locationName" {
            locationNameLabel.text = subtask.locationName
        }
        
        let image = subtask.isCompleted ?? false ? "checkmark.circle" : "circle"
        checkImage.image = UIImage(systemName: image, withConfiguration: checkConfiguration)
        
        if let categoryValue = subtask.category, let category = ActivityCategory(rawValue: categoryValue) {
            activityTypeButton.setImage(category.icon, for: .normal)
            if category == .uncategorized {
                activityTypeButton.setImage(UIImage(named: "task"), for: .normal)
            }
        } else {
            activityTypeButton.setImage(UIImage(named: "task"), for: .normal)
        }
        
        checkImage.tintColor = .secondaryLabel
        if let color = subtask.listColor {
            checkImage.tintColor = UIColor(ciColor: CIColor(string: color))
        }
        
        let viewTap = UITapGestureRecognizer(target: self, action: #selector(checkViewChanged(_:)))
        checkView.addGestureRecognizer(viewTap)
        
    }
    
    @objc func checkViewChanged(_ sender: UITapGestureRecognizer) {
        guard let subtask = row.value else { return }
        subtask.isCompleted = !(subtask.isCompleted ?? false)
        let image = subtask.isCompleted ?? false ? "checkmark.circle" : "circle"
        checkImage.image = UIImage(systemName: image, withConfiguration: checkConfiguration)
        delegate?.updateCompletion(task: subtask)

    }
}

final class SubtaskRow: Row<SubtaskCell>, RowType {
        required init(tag: String?) {
            super.init(tag: tag)
    }
}
