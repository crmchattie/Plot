//
//  HealthMetricCell.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-17.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class HealthMetricCell: UITableViewCell {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        label.textAlignment = .left
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let activityTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
                
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(activityTypeButton)
        
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -40).isActive = true
        
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
        subtitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        subtitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
        
        detailLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 4).isActive = true
        detailLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        detailLabel.rightAnchor.constraint(equalTo: activityTypeButton.leftAnchor, constant: -5).isActive = true
        detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        
        activityTypeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        activityTypeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5).isActive = true
        activityTypeButton.widthAnchor.constraint(equalToConstant: 29).isActive = true
        activityTypeButton.heightAnchor.constraint(equalToConstant: 29).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        subtitleLabel.text = ""
        detailLabel.text = ""
        activityTypeButton.setImage(nil, for: .normal)
    }
    
    func configure(_ healthMetric: HealthMetric) {
        var timeAgo = "today"
        var title = healthMetric.type.name
        if healthMetric.type == HealthMetricType.workout, let hkWorkout = healthMetric.hkWorkout {
            title = hkWorkout.workoutActivityType.name
            timeAgo = timeAgoSinceDate(hkWorkout.endDate)
        }
        
        titleLabel.text = title
        
        var total = "\(Int(healthMetric.total))"
        if healthMetric.type == HealthMetricType.weight {
            total = healthMetric.total.clean
        }
        
        subtitleLabel.text = "\(total) \(healthMetric.unit) \(timeAgo)"
        
        if let averageValue = healthMetric.average {
            var average = "\(Int(averageValue))"
            if healthMetric.type == HealthMetricType.weight {
                average = averageValue.clean
            }
            detailLabel.text = "\(average) \(healthMetric.unit) on average"
        }

        updateImage(healthMetric)
        
        titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        subtitleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        detailLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
    }
    
    func updateImage(_ healthMetric: HealthMetric) {
        var imageName = "activity"
        switch healthMetric.type {
        case .steps:
            imageName = "walking"
        case .nutrition:
            imageName = "activity"
        case .workout:
            if let workoutActivityType = healthMetric.hkWorkout?.workoutActivityType {
                if workoutActivityType == .running {
                    imageName = "running"
                }
                else if workoutActivityType == .cycling {
                    imageName = "cycling"
                }
                else {
                    imageName = "dumbell"
                }
            }
        case .heartRate:
            imageName = "heart-rate"
        case .weight:
            imageName = "body-weight-scales"
        }
        
        activityTypeButton.setImage(UIImage(named: imageName), for: .normal)
    }
}
