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
    
    var healthMetric: HealthMetric?
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    let titleLabelRight: UILabel = {
        let label = UILabel()
        label.textColor = .label
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
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
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
    
    func configure(_ sample: HKSample, segmentType: TimeSegmentType) {
        titleLabel.textColor = .label
        titleLabelRight.textColor = .label
        subtitleLabel.textColor = .secondaryLabel
        detailLabel.textColor = .secondaryLabel
        
        let interval = NSDateInterval(start: sample.startDate, end: sample.endDate)
        titleLabel.text = interval.duration.stringTime

        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "MMM dd, yyy hh:mm a"
        titleLabelRight.text = dateFormatter.string(from: sample.startDate)
        
        guard let healthMetric = healthMetric else {
            return
        }
        
        if case .workout = healthMetric.type, let workout = sample as? HKWorkout {
            let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            subtitleLabel.text = "\(totalEnergyBurned.clean) calories"
        }
        else if case .workoutMinutes = healthMetric.type, let workout = sample as? HKWorkout {
            let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            subtitleLabel.text = "\(totalEnergyBurned.clean) calories"
        }
        else if case .heartRate = healthMetric.type, let quantitySample = sample as? HKQuantitySample {
            let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let count = String(format: "%.1f", quantitySample.quantity.doubleValue(for: beatsPerMinuteUnit))
            let string = "\(count) bpm"
            titleLabel.text = string
            
            if segmentType == .week || segmentType == .month {
                dateFormatter.dateFormat = "MMM dd, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            } else if segmentType == .year {
                dateFormatter.dateFormat = "MMM, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            }
        }
        else if case .weight = healthMetric.type, let quantitySample = sample as? HKQuantitySample {
            let unit = HKUnit.pound()
            let count = quantitySample.quantity.doubleValue(for: unit)
            let string = "\(count) lb"
            titleLabel.text = string
            
            if segmentType == .week || segmentType == .month {
                dateFormatter.dateFormat = "MMM dd, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            } else if segmentType == .year {
                dateFormatter.dateFormat = "MMM, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            }
        }
        else if case .steps = healthMetric.type, let quantitySample = sample as? HKQuantitySample {
            let unit = HKUnit.count()
            let count = Int(quantitySample.quantity.doubleValue(for: unit))
            let string = "\(count) steps"
            titleLabel.text = string
            
            if segmentType == .week || segmentType == .month {
                dateFormatter.dateFormat = "MMM dd, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            } else if segmentType == .year {
                dateFormatter.dateFormat = "MMM, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            }
        }
        else if case HealthMetricType.nutrition(_) = healthMetric.type, let quantitySample = sample as? HKQuantitySample, let unit = healthMetric.unit {
            let count = Int(quantitySample.quantity.doubleValue(for: unit))
            let string = "\(count) \(healthMetric.unitName)"
            titleLabel.text = string
            
            if segmentType == .week || segmentType == .month {
                dateFormatter.dateFormat = "MMM dd, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            } else if segmentType == .year {
                dateFormatter.dateFormat = "MMM, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            }
        }
        else if case .activeEnergy = healthMetric.type, let quantitySample = sample as? HKQuantitySample, let unit = healthMetric.unit {
            let count = String(format: "%.1f", quantitySample.quantity.doubleValue(for: unit))
            let string = "\(count) \(healthMetric.unitName)"
            titleLabel.text = string
            
            if segmentType == .week || segmentType == .month {
                dateFormatter.dateFormat = "MMM dd, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            } else if segmentType == .year {
                dateFormatter.dateFormat = "MMM, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            }
        }
        else if case .flightsClimbed = healthMetric.type, let quantitySample = sample as? HKQuantitySample {
            let unit = HKUnit.count()
            let count = Int(quantitySample.quantity.doubleValue(for: unit))
            let string = "\(count) floors"
            titleLabel.text = string
            
            if segmentType == .week || segmentType == .month {
                dateFormatter.dateFormat = "MMM dd, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            } else if segmentType == .year {
                dateFormatter.dateFormat = "MMM, yyy"
                titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            }
        }
        else if case .sleep = healthMetric.type, let categorySample = sample as? HKCategorySample, let sleepValue = HKCategoryValueSleepAnalysis(rawValue: categorySample.value) {
            if segmentType != .day {
                dateFormatter.dateFormat = "MMM dd, yyy"
            }
            titleLabelRight.text = dateFormatter.string(from: sample.startDate)
            
            switch sleepValue {
            case .asleep:
                subtitleLabel.text = "Asleep"
            case .inBed:
                subtitleLabel.text = "In Bed"
            case .awake:
                subtitleLabel.text = "Awake"
            @unknown default:
                print("unknown default")
            }
        }
    }
}
