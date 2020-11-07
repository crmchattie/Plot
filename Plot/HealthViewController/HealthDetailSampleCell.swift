//
//  HealthDetailSampleCell.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-06.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import HealthKit

class HealthDetailSampleCell: UITableViewCell {
    
    var healthMetricType: HealthMetricType?
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    let titleLabelRight: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
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
        contentView.addSubview(titleLabelRight)
        
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: titleLabelRight.rightAnchor, constant: -10).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -2).isActive = true
        
        titleLabelRight.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        titleLabelRight.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20).isActive = true
        titleLabelRight.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -2).isActive = true
        
        subtitleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
        subtitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20).isActive = true
        
        detailLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 4).isActive = true
        detailLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
        detailLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20).isActive = true
        detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        subtitleLabel.text = ""
        detailLabel.text = ""
        titleLabelRight.text = ""
    }
    
    func configure(_ sample: HKSample) {
        titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        titleLabelRight.textColor = ThemeManager.currentTheme().generalTitleColor
        subtitleLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
        detailLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
        
        let interval = NSDateInterval(start: sample.startDate, end: sample.endDate)
        titleLabel.text = interval.duration.stringTime

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyy hh:mm a"
        
        titleLabelRight.text = dateFormatter.string(from: sample.startDate)
        
        guard let type = healthMetricType else {
            return
        }
        
        if type == .workout, let workout = sample as? HKWorkout {
            let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            subtitleLabel.text = "\(totalEnergyBurned.clean) calories"
        }
        else if type == .heartRate, let quantitySample = sample as? HKQuantitySample {
            let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let count = quantitySample.quantity.doubleValue(for: beatsPerMinuteUnit)
            let string = "\(count) bpm"
            if let text = titleLabel.text, text.isEmpty {
                titleLabel.text = string
            } else {
                subtitleLabel.text = string
            }
        }
        else if type == .weight, let quantitySample = sample as? HKQuantitySample {
            let unit = HKUnit.pound()
            let count = quantitySample.quantity.doubleValue(for: unit)
            let string = "\(count) lb"
            if let text = titleLabel.text, text.isEmpty {
                titleLabel.text = string
            } else {
                subtitleLabel.text = string
            }
        }
        else if type == .steps, let quantitySample = sample as? HKQuantitySample {
            let unit = HKUnit.count()
            let count = Int(quantitySample.quantity.doubleValue(for: unit))
            let string = "\(count) steps"
            if let text = titleLabel.text, text.isEmpty {
                titleLabel.text = string
            } else {
                subtitleLabel.text = string
            }
        }
    }
}
