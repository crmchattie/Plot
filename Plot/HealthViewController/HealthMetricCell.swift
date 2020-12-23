//
//  HealthMetricCell.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-17.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import HealthKit

class HealthMetricCell: UICollectionViewCell {

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
        label.numberOfLines = 0
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let activityTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var widthConstraint: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(activityTypeButton)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: leftAnchor),
            contentView.rightAnchor.constraint(equalTo: rightAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        widthConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5).isActive = true

        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
        subtitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        subtitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5).isActive = true

        detailLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 4).isActive = true
        detailLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        detailLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5).isActive = true
        detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0).isActive = true

        activityTypeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        activityTypeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
        activityTypeButton.widthAnchor.constraint(equalToConstant: 29).isActive = true
        activityTypeButton.heightAnchor.constraint(equalToConstant: 29).isActive = true
    }
    
    override func updateConstraints() {
        // Set width constraint to superview's width.
        widthConstraint?.constant = superview?.bounds.width ?? 0
        widthConstraint?.isActive = true
        super.updateConstraints()
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
        let isToday = NSCalendar.current.isDateInToday(healthMetric.date)
        var timeAgo = isToday ? "today" : timeAgoSinceDate(healthMetric.date)
        var title = healthMetric.type.name
        if case HealthMetricType.workout = healthMetric.type, let hkWorkout = healthMetric.hkSample as? HKWorkout {
            title = hkWorkout.workoutActivityType.name
            timeAgo = NSCalendar.current.isDateInToday(hkWorkout.endDate) ? "today" : timeAgoSinceDate(hkWorkout.endDate)
        }
        else if case HealthMetricType.nutrition(let value) = healthMetric.type {
            title = value
        }
        
        titleLabel.text = title
        
        var total = "\(Int(healthMetric.total))"
        var subtitleLabelText = "\(total) \(healthMetric.unitName) \(timeAgo)"
        if case HealthMetricType.weight = healthMetric.type {
            total = healthMetric.total.clean
            subtitleLabelText = "\(total) \(healthMetric.unitName) \(timeAgo)"
        }
        else if case HealthMetricType.sleep = healthMetric.type {
            total = TimeInterval(healthMetric.total).stringTimeShort
            subtitleLabelText = "\(total) \(timeAgo)"
        }
        else if case HealthMetricType.mindfulness = healthMetric.type {
            total = TimeInterval(healthMetric.total).stringTimeShort
            subtitleLabelText = "\(total) \(timeAgo)"
        }
        
        subtitleLabel.text = subtitleLabelText
        
        if let averageValue = healthMetric.average {
            var averageText = "\(Int(averageValue)) \(healthMetric.unitName) on average"
            if case HealthMetricType.weight = healthMetric.type {
                averageText = "\(averageValue.clean) \(healthMetric.unitName) on average"
            }
            else if case HealthMetricType.sleep = healthMetric.type {
                let shortTime = TimeInterval(averageValue).stringTimeShort
                averageText = "\(shortTime) on average"
            }
            else if case HealthMetricType.mindfulness = healthMetric.type {
                let shortTime = TimeInterval(averageValue).stringTimeShort
                averageText = "\(shortTime) on average"
            }
            
            detailLabel.text = averageText
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
            imageName = "nutrition"
        case .workout:
            if let hkWorkout = healthMetric.hkSample as? HKWorkout {
                let workoutActivityType = hkWorkout.workoutActivityType
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
        case .sleep:
            imageName = "sleep"
        case .mindfulness:
            imageName = "sleep"
        }
        
        activityTypeButton.setImage(UIImage(named: imageName), for: .normal)
    }
}
